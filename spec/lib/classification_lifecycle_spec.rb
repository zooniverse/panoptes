require 'spec_helper'

describe ClassificationLifecycle do
  let(:subject_set) { create(:subject_set, workflows: [classification.workflow]) }
  let(:sms_ids) do
    classification.subject_ids.map do |s_id|
      create(:set_member_subject, subject_set: subject_set, subject_id: s_id)
    end.map(&:id)
  end
  let(:classification) { build(:classification) }
  let(:workflow) { classification.workflow }
  let(:user) { classification.user }
  let(:action) { "create" }

  subject do
    ClassificationLifecycle.new(classification, action)
  end

  describe ".queue" do
    context "with create action" do
      let(:test_method) { :create }

      it 'should queue other actions' do
        allow(classification).to receive(:persisted?).and_return(true)
        expect(ClassificationWorker).to receive(:perform_async)
          .with(classification.id, "create")
        described_class.queue(classification, test_method)
      end

      it 'should raise an error if the classification is not persisted' do
        expect do
          described_class.queue(classification, test_method)
        end.to raise_error(ClassificationLifecycle::ClassificationNotPersisted)
      end
    end

    context "with update action" do
      let(:test_method) { :update }

      it 'should queue other actions' do
        allow(classification).to receive(:persisted?).and_return(true)
        expect(ClassificationWorker).to receive(:perform_async)
          .with(classification.id, "update")
        described_class.queue(classification, test_method)
      end

      it 'should raise en error if the classification is not persisted' do
        expect do
          described_class.queue(classification, test_method)
        end.to raise_error(ClassificationLifecycle::ClassificationNotPersisted)
      end
    end
  end

  shared_examples_for "create and update" do
    let!(:classification) { create(:classification) }

    context "when an anonymous user classification" do
      let(:classification) { create(:classification, user: nil) }

      it "should call the #update_classification_data" do
        expect(subject).to receive(:update_classification_data)
        subject.execute
      end

      it "should call the #queue_associated_workers" do
        expect(subject).to receive(:queue_associated_workers)
        subject.execute
      end

      context "when the classification has the already_seen metadata value" do
        let!(:classification) { create(:anonymous_already_seen_classification) }

        it 'should not count towards retirement' do
          expect(subject.send(:should_count_towards_retirement?)).to be false
          subject.execute
        end
      end
    end

    context "when the user has not already classified the subjects" do
      before(:each) do
        uss = instance_double("UserSeenSubject")
        allow(uss).to receive(:subjects_seen?).and_return(false)
        allow(UserSeenSubject).to receive(:find_by).and_return(uss)
      end

      it 'should count towards retirement' do
        expect(subject.send(:should_count_towards_retirement?)).to be true
        subject.execute
      end
    end

    context "when the user has already classified the subjects" do
      let!(:seen) do
        create(:user_seen_subject,
               user: classification.user,
               workflow: classification.workflow,
               subject_ids: classification.subject_ids)
      end

      it "should call the #create_recent" do
        expect(subject).to receive(:create_recent)
        subject.execute
      end

      it 'should not count towards retirement' do
        expect(subject.send(:should_count_towards_retirement?)).to be_falsey
        subject.execute
      end

      it 'should not queue the count worker' do
        expect(ClassificationCountWorker).to_not receive(:perform_async)
        subject.execute
      end
    end

    context "when invalid classification updates are made" do
      before(:each) do
        allow(classification).to receive(:valid?).and_return(false)
      end

      it 'should not schedule workers and error' do
        aggregate_failures "failure point" do
          expect(subject).to_not receive(:queue_associated_workers)
          expect{ subject.execute }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      it 'should not save and error' do
        aggregate_failures "failure point" do
          expect(subject).to_not receive(:save!)
          expect{ subject.execute }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'updating counters' do
      let(:subject_ids) { classification.subject_ids }

      it 'should call classification count worker' do
        expect(ClassificationCountWorker).to receive(:perform_async).with(subject_ids[0], workflow.id, action == "update")
        expect(ClassificationCountWorker).to receive(:perform_async).with(subject_ids[1], workflow.id, action == "update")
        subject.execute
      end

      context "when a user has seen the subjects before" do
        it 'should not call the classification count worker' do
          create(:user_seen_subject,
                 user: classification.user,
                 workflow: classification.workflow,
                 subject_ids: classification.subject_ids)
          expect(ClassificationCountWorker).to_not receive(:perform_async)
          subject.execute
        end
      end

      context "when a user is anonymous" do
        let(:classification) { create(:classification, user: nil) }

        it 'should call the classification count worker' do
          expect(ClassificationCountWorker).to receive(:perform_async).with(subject_ids[0], workflow.id, action == "update")
          expect(ClassificationCountWorker).to receive(:perform_async).with(subject_ids[1], workflow.id, action == "update")
          subject.execute
        end

        context "when the classification has the already_seen metadata value" do
          let!(:classification) do
            create(:anonymous_already_seen_classification)
          end

          it 'should not call the classification count worker' do
            expect(ClassificationCountWorker).to_not receive(:perform_async)
            subject.execute
          end
        end
      end

      context 'when classification is incomplete' do
        before(:each) do
          classification.update! completed: false
        end

        it 'should not queue the count worker' do
          expect(ClassificationCountWorker).to_not receive(:perform_async)
          subject.execute
        end
      end

      context 'when classification is complete' do
        it 'should queue the count worker' do
          expect(ClassificationCountWorker).to receive(:perform_async).with(subject_ids[0], workflow.id, action == "update")
          expect(ClassificationCountWorker).to receive(:perform_async).with(subject_ids[1], workflow.id, action == "update")
          subject.execute
        end
      end
    end

    it "should notify the subject selector" do
      allow(Panoptes.flipper).to receive(:enabled?).with("cellect").and_return(true)

      classification.subject_ids.each do |subject_id|
        expect(NotifySubjectSelectorOfSeenWorker).to receive(:perform_async).with(workflow.id, user.id, subject_id)
      end

      subject.execute
    end
  end

  context "for the create action" do
    let(:action) { "create" }

    it_behaves_like "create and update"

    it 'should ensure the classification save, workers and lifecycled_at calls are in order' do
      expect(subject).to receive(:update_classification_data).ordered
      expect(classification).to receive(:save!).ordered
      expect(subject).to receive(:queue_associated_workers).ordered
      expect(subject).to receive(:mark_classification_lifecycled_at).ordered
      subject.execute
    end

    context "when the lifecycled_at field is set" do
      let(:classification) do
        create(:classification, lifecycled_at: Time.zone.now)
      end

      it "should abort the worker asap" do
        expect(subject).not_to receive(:update_classification_data)
        subject.execute
      end
    end
  end

  context "for the update action" do
    let(:action) { "update" }

    it_behaves_like "create and update"
  end

  describe "#publish_data" do
    after(:each) { subject.publish_data }

    context "when classification is complete" do
      it 'should call the publish classification worker' do
        expect(PublishClassificationWorker)
        .to receive(:perform_async)
        .with(classification.id)
      end
    end

    context "when classification is incomplete" do
      let(:classification) { build(:classification, completed: false) }

      it 'should not call the publish classification worker' do
        expect(PublishClassificationWorker).not_to receive(:perform_async)
      end
    end
  end

  describe "#process_project_preference" do
    context "with a user" do
      let(:user) { create(:user) }
      let(:project) { create(:project) }
      let(:classification) { build(:classification, project: project, user: user) }

      it "should call the worker" do
        expect(UserProjectPreferencesWorker)
          .to receive(:perform_async)
          .with(user.id, project.id)
        subject.process_project_preference
      end
    end

    context "without a user" do
      let(:classification) { build(:classification, user: nil) }
      it 'should not call the worker' do
        expect(UserProjectPreferencesWorker).not_to receive(:perform_async)
        subject.process_project_preference
      end
    end
  end

  describe "#create_recent" do
    it 'should call the worker when not seen and completed user classification' do
      expect(RecentCreateWorker).to receive(:perform_async).with(classification.id)
      subject.create_recent
    end

    it 'should not call the worker when seen and completed user classification' do
      allow(subject).to receive(:subjects_are_unseen_by_user?).and_return(false)
      expect(RecentCreateWorker).not_to receive(:perform_async)
      subject.create_recent
    end

    it 'should not call the worker when not seen and not completed user classification' do
      allow(subject).to receive(:should_update_seen?).and_return(false)
      expect(RecentCreateWorker).not_to receive(:perform_async)
      subject.create_recent
    end
  end

  describe "#update_seen_subjects" do
    let(:classification) { create(:classification) }

    context "with a user" do
      it 'should call the worker to add the subject_id to the seen subjects' do
        expect(UserSeenSubjectsWorker)
          .to receive(:perform_async)
          .with(
            classification.user_id,
            classification.workflow_id,
            classification.subject_ids
          )
        subject.update_seen_subjects
      end
    end

    context "without a user" do
      let(:classification) { build(:classification, user: nil) }
      it 'should not call the worker' do
        expect(UserSeenSubjectsWorker).to_not receive(:perform_async)
        subject.update_seen_subjects
      end
    end

    it 'should not call the worker when subjects have been seen' do
      allow(subject).to receive(:subjects_are_unseen_by_user?).and_return(false)
      expect(UserSeenSubjectsWorker).to_not receive(:perform_async)
      subject.update_seen_subjects
    end
  end

  describe "#mark_expert_classifier" do
    context "without a logged in user" do
      let(:classification) { create(:classification, user: nil) }

      it 'should not mark the classification as expert' do
        subject.mark_expert_classifier
        classification.reload
        expect(classification.expert_classifier).to be_nil
      end
    end

    context "with a logged in user" do
      let(:setup_as_owner) { false }
      let(:roles) { [] }
      let(:classification) { build(:classification, gold_standard: true) }
      let!(:user_role) do
        create(:access_control_list, resource: classification.project,
          user_group: classification.user.identity_group,
          roles: roles)
      end

      before(:each) do
        classification.user = classification.project.owner if setup_as_owner
      end

      context "when the classifying user is the project owner" do
        let!(:setup_as_owner) { true }

        it 'should mark the classification as expert' do
          subject.mark_expert_classifier
          expect(classification.expert_classifier).to eq('owner')
        end

        context "when the subject is already seen" do
          it "should not mark the classification as expert" do
            allow(subject).to receive(:subjects_are_unseen_by_user?).and_return(false)
            subject.mark_expert_classifier
            expect(classification.expert_classifier).to be_nil
          end
        end
      end

      context "when the classifying user is an expert" do
        let(:roles) { ['expert'] }

        it 'should mark the classification as expert' do
          subject.mark_expert_classifier
          expect(classification.expert_classifier).to eq('expert')
        end
      end
    end
  end

  describe "#queue_associated_workers" do
    let(:classification) { create(:classification) }

    it "should call process_project_preference" do
      expect(subject).to receive(:process_project_preference)
      subject.queue_associated_workers
    end

    it "should call create_recent" do
      expect(subject).to receive(:create_recent)
      subject.queue_associated_workers
    end

    it "should call update_seen_subjects" do
      expect(subject).to receive(:update_seen_subjects)
      subject.queue_associated_workers
    end

    it "should call notify_subject_selector" do
      expect(subject).to receive(:notify_subject_selector)
      subject.queue_associated_workers
    end

    it "should call update_counters" do
      expect(subject).to receive(:update_counters)
      subject.queue_associated_workers
    end

    it "should call publish_data" do
      expect(subject).to receive(:publish_data)
      subject.queue_associated_workers
    end
  end

  describe "#update_classification_data" do
    let(:update_classification_data) { subject.update_classification_data }

    it "should call mark_expert_classifier" do
      expect(subject).to receive(:mark_expert_classifier)
      update_classification_data
    end

    it "should call add_seen_before_for_user" do
      expect(subject).to receive(:add_seen_before_for_user)
      update_classification_data
    end

    it "should call add_project_live_state" do
      expect(subject).to receive(:add_project_live_state)
      update_classification_data
    end

    it "should call add_user_groups" do
      expect(subject).to receive(:add_user_groups)
      update_classification_data
    end
  end

  describe "#add_project_live_state" do
    it "should leave all other metadata intact" do
      prev_metadata = classification.metadata
      subject.add_project_live_state
      updated_metadata = classification.metadata.except(:live_project)
      expect(updated_metadata).to eq(prev_metadata)
    end

    context "when the project is not live" do
      it "should return false for the project live metadata" do
        subject.add_project_live_state
        expect(classification.metadata[:live_project]).to eq(false)
      end
    end

    context "when the project is live" do
      it "should return false for the project live metadata" do
        allow_any_instance_of(Project).to receive(:live).and_return(true)
        subject.add_project_live_state
        expect(classification.metadata[:live_project]).to eq(true)
      end
    end
  end

  describe "#add_user_groups" do
    it "should leave all other metadata intact" do
      prev_metadata = classification.metadata
      subject.add_user_groups
      updated_metadata = classification.metadata.except(:user_group_ids)
      expect(updated_metadata).to eq(prev_metadata)
    end

    it "should not add identity group" do
      subject.add_user_groups
      expect(classification.metadata[:user_group_ids]).to eq([])
    end

    it "should add all other groups a user is currently in" do
      classification.save
      group1 = create :user_group
      group2 = create :user_group
      classification.user.memberships.create! user_group: group1, state: 'active'
      classification.user.memberships.create! user_group: group2, state: 'active'

      subject.add_user_groups
      expect(classification.metadata[:user_group_ids]).to match_array([group1.id, group2.id])
    end

    it 'should not add groups with inactive memberships' do
      classification.save
      classification.user.memberships.create! user_group: create(:user_group), state: 'inactive'

      subject.add_user_groups
      expect(classification.metadata[:user_group_ids]).to be_empty
    end
  end

  describe "#add_lifecycled_at" do
    it "should directly update the lifecycled_at timestamp via sql" do
      classification.save
      expect {
        subject.mark_classification_lifecycled_at
      }.to change {
        classification.lifecycled_at
      }
    end
  end

  describe "#add_seen_before_for_user" do
    it "should leave all other metadata intact" do
      prev_metadata = classification.metadata
      subject.add_seen_before_for_user
      updated_metadata = classification.metadata.except(:seen_before)
      expect(updated_metadata).to eq(prev_metadata)
    end

    context "when the classification is anonymous" do
      it "should not add the seen_before metadata value" do
        subject.add_seen_before_for_user
        expect(classification.metadata.has_key?(:seen_before)).to eq(false)
      end
    end

    context "when the classification is for a user" do
      context "when the user has not seen the subject before" do
        it "should not add the seen_before metadata value" do
          subject.add_seen_before_for_user
          expect(classification.metadata.has_key?(:seen_before)).to eq(false)
        end
      end

      context "when the user has seen the subject before" do
        it "should add the seen_before metadata value" do
          allow(subject).to receive(:subjects_are_unseen_by_user?).and_return(false)
          subject.add_seen_before_for_user
          expect(classification.metadata[:seen_before]).to eq(true)
        end
      end
    end
  end
end
