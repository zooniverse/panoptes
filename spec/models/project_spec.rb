require 'spec_helper'

describe Project, :type => :model do
  it "must have a user owner" do
    expect(build(:project)).to be_valid
    expect(build(:project, owner: nil)).to_not be_valid
  end
end
