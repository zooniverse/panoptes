require 'spec_helper'

shared_examples "dequeue subject" do
  after(:each) { subject.send(test_method) }
  
  context "complete classification" do 
    let(:classification) { create(:classification, completed: true) }

    context "is queued" do
      let!(:subject_queue) do
        create(:user_subject_queue,
               user: classification.user,
               workflow: classification.workflow,
               set_member_subject_ids: [classification.set_member_subject_id])
      end
      
      it 'should call dequeue_subject_for_user' do
        expect(UserSubjectQueue).to receive(:dequeue_subject_for_user)
          .with(user: classification.user,
                workflow: classification.workflow,
                set_member_subject_id: classification.set_member_subject.id)
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

shared_examples "update cellect" do
  it "should setup the add seen command to cellect" do
    expect(stubbed_cellect_connection).to receive(:add_seen)
      .with(
            subject_id: set_member_subject.id,
            workflow_id: workflow.id,
            user_id: user.id,
            host: 'example.com'
           )
    subject.send(test_method)
  end
end

shared_examples "create project preference" do
  context "with a user" do
    context "when no preference exists"  do
      let(:classification) { build(:classification) }
      
      it 'should create a project preference' do
        expect do
          subject.send(test_method)
        end.to change{ UserProjectPreference.count }.from(0).to(1)
      end

      it "should set the communication preferences to the user's default" do
        subject.send(test_method)
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
        subject.send(test_method)
      end.to_not change{ UserProjectPreference.count }
    end
  end

  context "without a user" do
    let(:classification) { build(:classification, user: nil) }
    it 'should not create a project preference' do
      expect do
        subject.send(test_method)
      end.to_not change{ UserProjectPreference.count }
    end
  end
end

shared_examples "update seen subjects" do
  after(:each) { subject.send(test_method) }
  context "with a user" do
    let(:classification) { build(:classification) }
    it 'should add the set_member_subject_id to the seen subjects' do
      expect(UserSeenSubject).to receive(:add_seen_subject_for_user)
        .with(user: classification.user,
              workflow: classification.workflow,
              set_member_subject_id: classification.set_member_subject.id)
    end
  end

  context "without a user" do
    let(:classification) { build(:classification, user: nil) }
    it 'should do nothing' do
      expect(UserSeenSubject).to_not receive(:add_seen_subject_for_user)
    end
  end
end

describe ClassificationLifecycle do
  subject do
    ClassificationLifecycle.new(classification, "http://test.host/")
  end

  before(:each) do
    stub_cellect_connection
  end
  
  describe "#on_create" do
    let(:test_method) { :on_create }

    it_behaves_like "dequeue subject"
    it_behaves_like "create project preference"
    it_behaves_like "update seen subjects"
    it_behaves_like "update cellect"
  end

  describe "#on_update" do
    let(:test_method) { :on_update }

    it_behaves_like "dequeue subject"
    it_behaves_like "update seen subjects"
    it_behaves_like "update cellect"
  end
end
