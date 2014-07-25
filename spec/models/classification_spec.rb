require 'spec_helper'

RSpec.describe Classification, :type => :model do
  it "should have a valid factory" do
    expect(build(:classification)).to be_valid
  end

  it "must have a project" do
    expect(build(:classification, project: nil)).to_not be_valid
  end

  it "must have a set_member_subject" do
    expect(build(:classification, set_member_subject: nil)).to_not be_valid
  end

  it "must have a workflow" do
    expect(build(:classification, workflow: nil)).to_not be_valid
  end

  it "must have a user_ip" do
    expect(build(:classification, user_ip: nil)).to_not be_valid
  end

  it "must have annotations" do
    expect(build(:classification, annotations: nil)).to_not be_valid
  end

  it "should be valid without a user" do
    expect(build(:classification, user: nil)).to be_valid
  end

  describe "#user_groups" do

    let(:expected_user_group) { create(:user_group) }
    let(:classification_with_user_group) { create(:classifaction_with_user_group, user_group: expected_user_group) }

    it "should have many user_groups" do
      expect(classification_with_user_group.user_group).to eq(expected_user_group)
    end
  end
end
