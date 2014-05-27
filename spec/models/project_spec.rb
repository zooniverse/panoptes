require 'spec_helper'

describe Project, :type => :model do
  it "should have a valid factory" do
    expect(build(:project)).to be_valid
  end

  it "must have a user owner" do
    expect(build(:project, owner: nil)).to_not be_valid
  end
end
