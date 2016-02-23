require 'spec_helper'

describe ClassificationLifecycle do
  let(:subject_set) { create(:subject_set, workflows: [classification.workflow]) }
  let(:sms_ids) do
    classification.subject_ids.map do |s_id|
      create(:set_member_subject, subject_set: subject_set, subject_id: s_id)
    end.map(&:id)
  end
  let(:subject_queue) do
    create(:subject_queue,
           user: classification.user,
           workflow: classification.workflow,
           set_member_subject_ids: sms_ids)
  end

  let(:classification) { build(:classification) }

  subject do
    ClassificationLifecycle.new(classification)
  end

  describe "#queue" do
    context "with create action" do
      let(:test_method) { :create }

      it 'should queue other actions' do
        allow(classification).to receive(:persisted?).and_return(true)
        expect(ClassificationWorker).to receive(:perform_async)
          .with(classification.id, "create")
        subject.queue(test_method)
      end

      it 'should raise an error if the classification is not persisted' do
        expect do
          subject.queue(test_method)
        end.to raise_error(ClassificationLifecycle::ClassificationNotPersisted)
      end
    end

    context "with update action" do
      let(:test_method) { :update }

      it 'should queue other actions' do
        allow(classification).to receive(:persisted?).and_return(true)
        expect(ClassificationWorker).to receive(:perform_async)
          .with(classification.id, "update")
        subject.queue(test_method)
      end

      it 'should raise en error if the classification is not persisted' do
        expect do
          subject.queue(test_method)
        end.to raise_error(ClassificationLifecycle::ClassificationNotPersisted)
      end
    end

    context 'when classification is incomplete', sidekiq: :inline do
      before(:each) do
        classification.completed = false
        classification.save
      end

      it 'should not queue the count worker' do
        expect(ClassificationCountWorker).to_not receive(:perform_async)
        subject.queue(:create)
      end
    end

    context 'when classification is complete', sidekiq: :inline do

      it 'should queue the count worker' do
        classification.save
        times = case classification.subject_ids.size
        when 1
          :once
        when 2
          :twice
        end
        expect(ClassificationCountWorker).to receive(:perform_async).send(times)
        subject.queue(:create)
      end
    end
  end

  describe "#transact!" do
    let!(:classification) { create(:classification) }

    context "transact! after each spec" do

      after(:each) do
        subject.transact! { true }
      end

      context "when an anonymous user classification" do
        let(:classification) { create(:classification, user: nil) }

        it "should wrap the calls in transactions" do
          expect(Classification).to receive(:transaction).twice
            .and_call_original
        end

        it "should call the #update_classification_data" do
          expect(subject).to receive(:update_classification_data)
        end

        it "should not attempt to update the seen subjects" do
          expect_any_instance_of(UserSeenSubject).to_not receive(:subjects_seen?)
        end

        it "should evaluate the block" do
          expect(subject).to receive(:instance_eval)
        end

        it "should call the #create_recent" do
          aggregate_failures "recents" do
            expect(subject).to receive(:create_recent).and_call_original
            expect(Recent).to_not receive(:create_from_classification)
          end
        end

        it "should call the #update_seen_subjects" do
          expect(subject).to receive(:update_seen_subjects)
        end

        it "should call #publish_data" do
          expect(subject).to receive(:publish_data)
        end

        it "should call the #refresh_queue" do
          expect(subject).to receive(:refresh_queue)
        end

        context "when the classification has the already_seen metadata value" do
          let!(:classification) { create(:anonymous_already_seen_classification) }

          it 'should not count towards retirement' do
            expect(subject.should_count_towards_retirement?).to be false
          end
        end
      end

      context "when the user has not already classified the subjects" do
        before(:each) do
          uss = instance_double("UserSeenSubject")
          allow(uss).to receive(:subjects_seen?).and_return(false)
          allow(UserSeenSubject).to receive(:find_by).and_return(uss)
        end

        it "should wrap the calls in transactions" do
          expect(Classification).to receive(:transaction).twice
            .and_call_original
        end

        it "should call the #update_classification_data" do
          expect(subject).to receive(:update_classification_data)
        end

        it "should evaluate the block" do
          expect(subject).to receive(:instance_eval)
        end

        it "should call the #create_recent" do
          aggregate_failures "recents" do
            expect(subject).to receive(:create_recent).and_call_original
            expect(Recent).to receive(:create_from_classification)
          end
        end

        it "should call the instance_eval on the passed block" do
          expect(subject).to receive(:instance_eval)
        end

        it "should call the #update_seen_subjects" do
          expect(subject).to receive(:update_seen_subjects)
        end

        it "should call the #refresh_queue" do
          expect(subject).to receive(:refresh_queue)
        end

        it "should call #publish_data" do
          expect(subject).to receive(:publish_data)
        end

        it 'should count towards retirement' do
          expect(subject.should_count_towards_retirement?).to be true
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
          aggregate_failures "recents" do
            expect(subject).to receive(:create_recent).and_call_original
            expect(Recent).to_not receive(:create_from_classification)
          end
        end

        it 'should not count towards retirement' do
          expect(subject.should_count_towards_retirement?).to be_falsey
        end

        it 'should not queue the count worker' do
          expect(ClassificationCountWorker).to_not receive(:perform_async)
        end
      end
    end

    context "when invalid classification updates are made" do
      before(:each) do
        allow_any_instance_of(Classification).to receive(:save!)
          .and_raise(ActiveRecord::RecordInvalid.new(classification))
      end

      it "should not call the instance_eval on the passed block" do
        aggregate_failures "failure point" do
          expect(subject).to_not receive(:instance_eval)
          expect{ subject.transact! }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      it 'should not call #create_recent' do
        aggregate_failures "failure point" do
          expect(subject).to_not receive(:create_recent)
          expect{ subject.transact! }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      it 'should not call #update_seen_subjects' do
        aggregate_failures "failure point" do
          expect(subject).to_not receive(:update_seen_subjects)
          expect{ subject.transact! }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      it 'should not call #refresh_queue' do
        aggregate_failures "failure point" do
          expect(subject).to_not receive(:refresh_queue)
          expect{ subject.transact! }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      it 'should not call #publish_data' do
        aggregate_failures "failure point" do
          expect(subject).to_not receive(:publish_data)
          expect{ subject.transact! }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      it 'should not call should_count_towards_retirement?' do
        aggregate_failures "failure point" do
          expect(subject).to_not receive(:should_count_towards_retirement?)
          expect{ subject.transact! }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
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

  describe "#create_project_preference" do
    context "with a user" do
      let(:user) { create(:user) }
      let(:project) { create(:project) }
      let(:classification) { build(:classification, project: project, user: user) }

      context "when no preference exists"  do
        it 'should create a project preference' do
          expect do
            subject.process_project_preference
          end.to change{ UserProjectPreference.count }.from(0).to(1)
        end

        it 'should increment a count on the associated project' do
          expect do
            subject.process_project_preference
            project.reload
          end.to change{project.classifiers_count}.from(0).to(1)
        end

        it "should set the communication preferences to the user's default" do
          subject.process_project_preference
          email_pref = UserProjectPreference
            .where(user: classification.user, project: classification.project)
            .first.email_communication
          expect(email_pref).to eq(classification.user.project_email_communication)
        end

        it "should save the preference" do
          expect_any_instance_of(UserProjectPreference).to receive(:save!)
          subject.process_project_preference
        end
      end

      context "when a preference exists" do
        let!(:upp) { create(:user_project_preference, user: user, project: project) }

        it "should not create a project preference" do
          expect do
            subject.process_project_preference
          end.to_not change{ UserProjectPreference.count }
        end

        it "should touch the updated_at timestamp" do
          expect_any_instance_of(UserProjectPreference).to receive(:touch)
          subject.process_project_preference
        end

        context "when the upp was created before the first classification was received" do
          let!(:upp) do
            create(:user_project_preference, email_communication: nil, user: user, project: project)
          end

          it "should update the email_communication if not set" do
            subject.process_project_preference
            expect(upp.reload.email_communication).to be_truthy
          end

          it 'should increment a count on the associated project' do
            expect do
              subject.process_project_preference
              project.reload
            end.to change{project.classifiers_count}.from(0).to(1)
          end
        end
      end
    end

    context "without a user" do
      let(:classification) { build(:classification, user: nil) }
      it 'should not create a project preference' do
        expect do
          subject.process_project_preference
        end.to_not change{ UserProjectPreference.count }
      end
    end
  end

  describe "#update_seen_subjects" do
    let(:seen_params) do
      { user: classification.user,
        workflow: classification.workflow,
        subject_ids: classification.subject_ids }
    end

    context "with a user", :cellect do
      it 'should add the subject_id to the seen subjects' do
        expect(UserSeenSubject).to receive(:add_seen_subjects_for_user)
        .with(seen_params)
        subject.update_seen_subjects
      end

      it "should not call cellect seen worker" do
        expect(SeenCellectWorker).not_to receive(:perform_async)
        subject.update_seen_subjects
      end

      context "when cellect is on" do
        before do
          allow(Panoptes).to receive(:cellect_on).and_return(true)
        end

        it "should not call the worker by default" do
          expect(SeenCellectWorker).not_to receive(:perform_async)
          subject.update_seen_subjects
        end

        context "when the workflow is using cellect" do
          before do
            allow(classification.workflow)
            .to receive(:using_cellect?).and_return(true)
          end

          it "should call cellect seen worker for each subject id" do
            classification.subject_ids.each do |subject_id|
              expect(SeenCellectWorker)
              .to receive(:perform_async)
              .with(seen_params[:workflow].id, seen_params[:user].id, subject_id)
            end
            subject.update_seen_subjects
          end
        end
      end
    end

    context "without a user" do
      let(:classification) { build(:classification, user: nil) }
      it 'should do nothing' do
        expect(UserSeenSubject).to_not receive(:add_seen_subject_for_user)
      end
    end
  end

  describe "#refresh_queue" do
    let(:workflow_id) { classification.workflow_id }
    let(:user_id) { classification.user_id }

    after(:each) { subject.refresh_queue }

    context "when no queue exists" do
      it "should not call Enqueue worker" do
        expect(EnqueueSubjectQueueWorker).to_not receive(:perform_async)
      end
    end

    context "when a queue exists" do
      before(:each) do
        subject_queue
        allow_any_instance_of(SubjectQueue)
          .to receive(:below_minimum?)
          .and_return(below_min)
      end

      context "when queue is not below min" do
        let(:below_min) { false }

        it "should not call Enqueue worker" do
          expect(EnqueueSubjectQueueWorker).to_not receive(:perform_async)
        end
      end

      context "when queue is below min" do
        let(:below_min) { true }

        it "should call Enqueue worker" do
          expect(EnqueueSubjectQueueWorker).to receive(:perform_async)
          .with(subject_queue.id)
        end

        context "when subject belongs to many sets" do
          let(:set_ids) { [1,2,3] }

          it "should call Enqueue worker for each set" do
            allow(subject).to receive(:subjects_workflow_subject_sets).and_return(set_ids)
            allow(SubjectQueue).to receive(:by_set).and_return(SubjectQueue.all)
            set_ids.each do |set_id|
              expect(EnqueueSubjectQueueWorker).to receive(:perform_async)
                .with(subject_queue.id)
            end
          end
        end
      end
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

  describe "#update_classification_data" do
    let(:update_classification_data) { subject.update_classification_data }

    it "should wrap the calls in a transaction" do
      expect(Classification).to receive(:transaction)
      update_classification_data
    end

    it "should call add_project_live_state" do
      expect(subject).to receive(:add_project_live_state)
      update_classification_data
    end

    it "should call add_lifecycled_at" do
      expect(subject).to receive(:add_lifecycled_at)
      update_classification_data
    end

    it "should call add_seen_before_for_user" do
      expect(subject).to receive(:add_seen_before_for_user)
      update_classification_data
    end

    it "should call mark_expert_classifier" do
      expect(subject).to receive(:mark_expert_classifier)
      update_classification_data
    end

    it "should call classification save!" do
      expect(classification).to receive(:save!)
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
      group1 = create :user_group
      group2 = create :user_group
      classification.user.memberships.create! user_group: group1
      classification.user.memberships.create! user_group: group2

      subject.add_user_groups
      expect(classification.metadata[:user_group_ids]).to match_array([group1.id, group2.id])
    end
  end

  describe "#add_lifecycled_at" do
    it "should mark the lifecycled_at timestamp" do
      subject.add_lifecycled_at
      prev, current = classification.changes[:lifecycled_at]
      expect(prev).to be_nil
      expect(current).to be_a(ActiveSupport::TimeWithZone)
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
