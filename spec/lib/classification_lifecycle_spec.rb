require 'spec_helper'

describe ClassificationLifecycle do
  describe "#dequeue_subject" do
    it 'should call dequeue_subject_for_user' do
      classification = create(:classification, completed: false, enqueued: true)
      expect(UserEnqueuedSubject).to receive(:dequeue_subject_for_user)
        .with(user: classification.user,
              workflow: classification.workflow,
              subject_id: classification.set_member_subject.id)
      classification.completed = true
      classification.save!
    end

    it 'should not call dequeue_subject_for_user when not enqueued' do
      classification = create(:classification, completed: false, enqueued: false)
      expect(UserEnqueuedSubject).to_not receive(:dequeue_subject_for_user)
      classification.completed = true
      classification.save!
    end

    it 'should not call dequeue_subject_for_use when :incomplete' do
      classification = create(:classification, completed: false)
      expect(UserEnqueuedSubject).to_not receive(:dequeue_subject_for_user)
      classification.save!
    end
  end
  
  describe "#create_project_preference" do
    context "with a user" do
      context "when no preference exists"  do
        it 'should create a project preference' do
          classification = build(:classification)
          expect do
            expect{ create_project_preference }.to change{ UserProjectPreference.count }.from(0).to(1)
          end
        end
      end

      context "when a preference exists" do
        it "should not create a project preference" do
          user = create(:user)
          project = create(:project)
          create(:user_project_preference, user: user, project: project)
          classification = build(:classification, project: project, user: user)
          expect{ classification.create_project_preference }.to_not change{ UserProjectPreference.count }
        end
      end
    end

    context "without a user" do
      it 'should not create a project preference' do
        classification = build(:classification, user: nil)
        expect{ classification.create_project_preference }.to_not change{ UserProjectPreference.count }
      end
    end
  end

  describe "#update_seen_subjects" do
    context "with a user" do
      it 'should add the set_member_subject_id to the seen subjects' do
        classification = build(:classification)
        expect(UserSeenSubject).to receive(:add_seen_subject_for_user)
          .with(user: classification.user,
                workflow: classification.workflow,
                set_member_subject_id: classification.set_member_subject.id)
        classification.update_seen_subjects
      end
    end

    context "without a user" do
      it 'should do nothing' do
        classification = build(:classification, user: nil)
        expect(UserSeenSubject).to_not receive(:add_seen_subject_for_user)
        classification.update_seen_subjects
      end
    end
  end
end
