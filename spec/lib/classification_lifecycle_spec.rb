require 'spec_helper'

describe ClassificationLifecycle do
  let!(:subject_set) { create(:subject_set, workflows: [classification.workflow]) }
  let!(:sms_ids) do
    classification.subject_ids.map do |s_id|
      create(:set_member_subject, subject_set: subject_set, subject_id: s_id)
    end.map(&:id)
  end

  let!(:subject_queue) do
    create(:subject_queue,
           user: classification.user,
           workflow: classification.workflow,
           set_member_subject_ids: sms_ids)
  end

  subject do
    ClassificationLifecycle.new(classification)
  end

  before(:each) do
    allow(MultiKafkaProducer).to receive(:publish)
  end

  describe "#queue" do
    let(:classification) { build(:classification) }

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
    let(:classification) { create(:classification) }

    after(:each) do
      subject.transact! { true }
    end

    context "when an anonymous user classification" do
      let!(:classification) { create(:classification, user: nil) }

      it "should wrap the calls in a transaction" do
        expect(Classification).to receive(:transaction)
      end

      it "should not attempt to update the seen subjects" do
        expect_any_instance_of(UserSeenSubject).to_not receive(:subjects_seen?)
      end

      it "should still evaluate the block" do
        expect(subject).to receive(:instance_eval)
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

      it "should wrap the calls in a transaction" do
        expect(Classification).to receive(:transaction)
      end

      it "should call the #mark_expert_classifier method" do
        expect(subject).to receive(:mark_expert_classifier).once
      end

      it "should call the #update_seen_subjects method" do
        expect(subject).to receive(:update_seen_subjects).once
      end

      it "should call the instance_eval on the passed block" do
        expect(subject).to receive(:instance_eval).once
      end

      it "should call the #publish_to_kafka method" do
        expect(subject).to receive(:publish_to_kafka).once
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

      it "should wrap the calls in a transaction" do
        expect(Classification).to receive(:transaction)
      end

      it "should not call the #mark_expert_classifier method" do
        expect(subject).to_not receive(:mark_expert_classifier)
      end

      it "should call the instance_eval on the passed block" do
        expect(subject).to receive(:instance_eval)
      end

      it "should call the #publish_to_kafka method" do
        expect(subject).to receive(:publish_to_kafka).once
      end

      it 'should not count towards retirement' do
        expect(subject.should_count_towards_retirement?).to be_falsey
      end

      it 'should not queue the count worker' do
        expect(ClassificationCountWorker).to_not receive(:perform_async)
      end
    end
  end

  describe "#publish_to_kafka" do
    after(:each) { subject.publish_to_kafka }

    context "when classificaiton is completed" do
      let(:classification) { build(:classification) }

      it 'should publish to kafka' do
        serialized = ClassificationSerializer.serialize(classification).to_json
        expect(MultiKafkaProducer).to receive(:publish)
          .with('classifications', [classification.project.id, serialized])
      end
    end

    context "when classificaiton is incomplete" do
      let(:classification) { build(:classification, completed: false) }

      it 'should do nothing' do
        expect(MultiKafkaProducer).to_not receive(:publish)
      end
    end
  end

  describe "#create_project_preference" do
    context "with a user" do
      context "when no preference exists"  do
        let(:classification) { build(:classification) }

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
      let(:classification) { build(:classification) }
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
        classification.save
        subject.mark_expert_classifier
        classification.reload
      end

      context "when the classifying user is the project owner" do
        let!(:setup_as_owner) { true }

        it 'should mark the classification as expert' do
          expect(classification.expert_classifier).to eq('owner')
        end
      end

      context "when the classifying user is an expert" do
        let(:roles) { ['expert'] }

        it 'should mark the classification as expert' do
          expect(classification.expert_classifier).to eq('expert')
        end
      end
    end
  end
end
