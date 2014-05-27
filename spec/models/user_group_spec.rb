require 'spec_helper'

describe UserGroup, :type => :model do
  it "should have a valid factory" do
    expect(build(:user_group)).to be_valid
  end
end
