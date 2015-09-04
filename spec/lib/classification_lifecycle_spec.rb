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

  before(:each) do
    allow(MultiKafkaProducer).to receive(:publish)
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

        it "should call the #refresh_queue" do
          expect(subject).to receive(:refresh_queue)
        end

        it "should call the #publish_to_kafka" do
          expect(subject).to receive(:publish_to_kafka)
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

        it "should call the #publish_to_kafka method" do
          expect(subject).to receive(:publish_to_kafka)
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

      it 'should not call #publish_to_kafka' do
        aggregate_failures "failure point" do
          expect(subject).to_not receive(:publish_to_kafka)
          expect{ subject.transact! }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      it 'should not call #save_to_cassandra' do
        aggregate_failures "failure point" do
          expect(subject).to_not receive(:save_to_cassandra)
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

  describe "#publish_to_kafka" do
    after(:each) { subject.publish_to_kafka }

    context "when classificaiton is completed" do

      it 'should publish to kafka' do
        serialized = KafkaClassificationSerializer.serialize(classification, include: 'subjects').to_json
        expect(MultiKafkaProducer).to receive(:publish)
        .with('classifications', [classification.project.id, serialized])
      end
    end

    context "when classification is incomplete" do
      let(:classification) { build(:classification, completed: false) }

      it 'should do nothing' do
        expect(MultiKafkaProducer).to_not receive(:publish)
      end
    end
  end

  describe "#save_to_cassandra" do
    after(:each) { subject.save_to_cassandra }

    context "when classification is complete" do

      it 'should create a cassandra record' do
        expect(Cassandra::Classification).to receive(:from_ar_model).with(classification)
      end
    end

    context "when classification is incomplete" do
      let(:classification) { build(:classification, completed: false) }

      it 'should do nothing' do
        expect(Cassandra::Classification).to_not receive(:from_ar_model)
      end
    end
  end

  describe "#create_project_preference" do
    context "with a user" do
      context "when no preference exists"  do

        it 'should create a project preference' do
          expect do
            subject.create_project_preference
          end.to change{ UserProjectPreference.count }.from(0).to(1)
        end

        it "should set the communication preferences to the user's default" do
          subject.create_project_preference
          email_pref = UserProjectPreference
          .where(user: classification.user, project: classification.project)
          .first.email_communication
          expect(email_pref).to eq(classification.user
            .project_email_communication)
        end

      end
    end

    context "when a preference exists" do
      let(:user) { create(:user) }
      let(:project) { create(:project) }
      let(:classification) do
        build(:classification, project: project, user: user)
      end

      it "should not create a project preference" do
        create(:user_project_preference, user: user, project: project)
        expect do
          subject.create_project_preference
        end.to_not change{ UserProjectPreference.count }
      end
    end

    context "without a user" do
      let(:classification) { build(:classification, user: nil) }
      it 'should not create a project preference' do
        expect do
          subject.create_project_preference
        end.to_not change{ UserProjectPreference.count }
      end
    end
  end

  describe "#update_seen_subjects" do
    after(:each) { subject.update_seen_subjects }

    context "with a user" do
      it 'should add the subject_id to the seen subjects' do
        expect(UserSeenSubject).to receive(:add_seen_subjects_for_user)
        .with(user: classification.user,
          workflow: classification.workflow,
          subject_ids: classification.subject_ids)
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

      before(:each) { subject_queue }

      context "when queue is not below min" do

        it "should not call Enqueue worker" do
          allow(subject).to receive(:below_threshold_queue?).and_return(false)
          expect(EnqueueSubjectQueueWorker).to_not receive(:perform_async)
        end
      end

      context "when queue is below min" do

        it "should call Enqueue worker" do
          allow(subject).to receive(:below_threshold_queue?).and_return(true)
          expect(EnqueueSubjectQueueWorker).to receive(:perform_async)
            .with(workflow_id, user_id, nil)
        end
      end

      context "when workflow is grouped and the set queue is below min" do

        it "should call Enqueue worker with the subject sets" do
          smses = SetMemberSubject.where(subject_id: classification.subject_ids.first)
          allow_any_instance_of(Workflow).to receive(:grouped).and_return(true)
          allow(SetMemberSubject).to receive(:by_subject_workflow).and_return(smses)
          allow(subject).to receive(:below_threshold_queue?).and_return(true)
          smses.each do |sms|
            expect(EnqueueSubjectQueueWorker).to receive(:perform_async)
              .with(workflow_id, user_id, sms.subject_set_id)
            end
        end
      end

      context "when subject belongs to many sets" do
        let(:set_ids) { [1,2,3] }

        it "should call Enqueue worker for each set below min" do
          allow(subject).to receive(:subjects_workflow_subject_sets).and_return(set_ids)
          allow(subject).to receive(:below_threshold_queue?).and_return(true)
          set_ids.each do |set_id|
            expect(EnqueueSubjectQueueWorker).to receive(:perform_async)
              .with(workflow_id, user_id, set_id)
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
