require 'spec_helper'

describe Subject, :type => :model do
  it "should have a valid factory" do
    expect(build(:subject)).to be_valid
  end
end
