require 'spec_helper'

RSpec.describe UserSeenSubject, :type => :model do
  let(:user_seen_subject) { build(:user_seen_subject) }

  it "should have a valid factory" do
    expect(user_seen_subject).to be_valid
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

  describe "#add_subject" do
    it "should add a subject's id to the subject_ids array" do
      uss = user_seen_subject
      s = build(:subject)
      uss.add_subject(s)
      expect(uss.subject_ids).to include(s.id)
    end
  end
end
