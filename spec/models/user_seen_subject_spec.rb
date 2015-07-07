require 'spec_helper'

def created_uss
  UserSeenSubject.where(params.except(:subject)).first
end

RSpec.describe UserSeenSubject, :type => :model do
  let(:user_seen_subject) { build(:user_seen_subject, subject_ids: []) }

  it "should have a valid factory" do
    expect(user_seen_subject).to be_valid
  end

  describe "::add_seen_subjects_for_user" do
    let(:subject) { create(:subject) }
    let(:params) { { user: user, workflow: workflow, subject_ids: [subject.id] } }

    context "when no user or workflow exists" do
      let(:workflow) { nil }
      let(:user) { nil }

      it "should fail" do
        expect do
          UserSeenSubject.add_seen_subjects_for_user(params)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "user and workflow exist" do
      let(:workflow) { user_seen_subject.workflow }
      let(:user) { user_seen_subject.user }

      context "no user_seen_subject exists" do

        it "should create a new user_seen_subject" do
          expect do
            UserSeenSubject.add_seen_subjects_for_user(params)
          end.to change{ UserSeenSubject.count }.by(1)
        end

        it "should add the subject id to the subject_ids array" do
          UserSeenSubject.add_seen_subjects_for_user(params)
          expect(created_uss.subject_ids).to eq([ subject.id ])
        end
      end

      context "user_seen_subject for workflow and user exists" do
        let!(:save_uss) { user_seen_subject.save }

        it "should not create a new user_seen_subejct" do
          expect do
            UserSeenSubject.add_seen_subjects_for_user(params)
          end.not_to change{ UserSeenSubject.count }
        end

        it "should add the subject id to the subject_ids array" do
          UserSeenSubject.add_seen_subjects_for_user(params)
          user_seen_subject.reload
          expect(user_seen_subject.subject_ids).to include(subject.id)
        end
      end
    end
  end

  describe "::count_user_activity" do
    let(:user_seen_subject) { create(:user_seen_subject, build_real_subjects: false) }
    let!(:another_uss) { create(:user_seen_subject, user: user_seen_subject.user, build_real_subjects: false) }
    let(:workflow_ids) { [user_seen_subject, another_uss].map(&:workflow_id) }
    let(:all_seen_counts) { [user_seen_subject, another_uss].map(&:subject_ids).flatten.size }

    it "should sum all the seen subjects across all workflows" do
      count = UserSeenSubject.count_user_activity(user_seen_subject.user_id)
      expect(count).to eq(all_seen_counts)
    end

    it "should sum all the seen subjects across specific workflow ids" do
      count = UserSeenSubject.count_user_activity(user_seen_subject.user_id, workflow_ids)
      expect(count).to eq(all_seen_counts)
    end

    it "should sum all the seen subjects across a specific workflow" do
      count = UserSeenSubject.count_user_activity(user_seen_subject.user_id, user_seen_subject.workflow_id)
      expect(count).to eq(user_seen_subject.subject_ids.size)
    end

    context "when no counts exist for the user" do

      it "should return 0" do
        count = UserSeenSubject.count_user_activity(user_seen_subject.user_id+1)
        expect(count).to eq(0)
      end
    end
  end

  describe "#user" do
    it "should not be valid without a user" do
      expect(build(:user_seen_subject, user: nil)).to_not be_valid
    end

    it "should belong to a user" do
      expect(create(:user_seen_subject).user).to be_a(User)
    end
  end

  describe "#workflow" do
    it "should not be valid without a workflow" do
      expect(build(:user_seen_subject, workflow: nil)).to_not be_valid
    end

    it "should belong to a workflow" do
      expect(create(:user_seen_subject).workflow).to be_a(Workflow)
    end
  end

  describe "#subjects_seen?" do
    let(:uss) { build(:user_seen_subject) }

    it "should return true if any id param is in the list" do
      seen_id = uss.subject_ids.sample(1)
      expect(uss.subjects_seen?(seen_id)).to be_truthy
    end

    it "should return false if no id param is in the list" do
      seen_id = uss.subject_ids.last + 1
      expect(uss.subjects_seen?(seen_id)).to be_falsey
    end
  end
end
