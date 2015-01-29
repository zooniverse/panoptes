require 'spec_helper'

describe ClassificationLifecycle do
  subject do
    ClassificationLifecycle.new(classification)
  end

  before(:each) do
    allow(MultiKafkaProducer).to receive(:publish)
    stub_cellect_connection
  end

  describe "#queue" do
    let(:classification) { create(:classification) }

    after(:each) do
      subject.queue(test_method)
    end

    context "with create action" do
      let(:test_method) { :create }

      it 'should queue other actions' do
        expect(ClassificationWorker).to receive(:perform_async)
                                         .with(classification.id, :create)
      end
    end

    context "with update action" do
      let(:test_method) { :update }

      it 'should queue other actions' do
        expect(ClassificationWorker).to receive(:perform_async)
                                         .with(classification.id, :update )
      end
    end
  end

  describe "#transact!" do
    let(:classification) { create(:classification) }

    describe "the classification lifecycle methods" do

      it "should wrap the calls in a transaction" do
        subject
        expect(Classification).to receive(:transaction)
        subject.transact!
      end

      it "should call the #mark_expert_classifier method" do
        expect(subject).to receive(:mark_expert_classifier).once
        subject.transact!
      end

      it "should call the #update_seen_subjects method" do
        expect(subject).to receive(:update_seen_subjects).once
        subject.transact!
      end

      it "should call the #dequeue_subject method" do
        expect(subject).to receive(:dequeue_subject).once
        subject.transact!
      end

      it "should call the instance_eval on the block if passed a block" do
        expect(subject).to receive(:instance_eval).once
        subject.transact! { true }
      end

      it "should call the #publish_to_kafka method" do
        expect(subject).to receive(:publish_to_kafka).once
        subject.transact!
      end
    end
  end


  describe "publish_to_kafka" do
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

  describe "#dequeue_subject" do
    after(:each) { subject.dequeue_subject }

    context "complete classification" do
      let(:classification) { create(:classification, completed: true) }

      context "is queued" do
        let!(:subject_queue) do
          create(:user_subject_queue,
                 user: classification.user,
                 workflow: classification.workflow,
                 set_member_subject_ids: classification.set_member_subject_ids)
        end

        it 'should call dequeue_subject_for_user' do
          expect(UserSubjectQueue).to receive(:dequeue_subjects_for_user)
                                       .with(user: classification.user,
                                             workflow: classification.workflow,
                                             set_member_subject_ids: classification.set_member_subject_ids)
        end
      end

      context "is not queued" do
        it 'should not call dequeue_subject_for_user when not enqueued' do
          classification = create(:classification, completed: true)
          expect(UserSubjectQueue).to_not receive(:dequeue_subject_for_user)
        end
      end
    end

    context "incomplete classification" do
      let(:classification) { create(:classification, completed: false) }

      it 'should not call dequeue_subject_for_use when incomplete' do
        expect(UserSubjectQueue).to_not receive(:dequeue_subject_for_user)
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
      it 'should add the set_member_subject_id to the seen subjects' do
        expect(UserSeenSubject).to receive(:add_seen_subjects_for_user)
                                    .with(user: classification.user,
                                          workflow: classification.workflow,
                                          set_member_subject_ids: classification.set_member_subject_ids)
      end
    end

    context "without a user" do
      let(:classification) { build(:classification, user: nil) }
      it 'should do nothing' do
        expect(UserSeenSubject).to_not receive(:add_seen_subject_for_user)
      end
    end
  end

  describe "#update_cellect" do
    let(:classification) { create(:classification) }

    it "should setup the add seen command to cellect" do
      expect(stubbed_cellect_connection).to receive(:add_seen)
                                             .with(
                                               subject_id: classification.set_member_subject_ids.first,
                                               workflow_id: classification.workflow.id,
                                               user_id: classification.user.id,
                                               host: 'http://test.host/'
                                             )
      subject.update_cellect('http://test.host/')
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
