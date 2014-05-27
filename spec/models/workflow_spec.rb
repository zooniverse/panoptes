require 'spec_helper'

describe Workflow, :type => :model do
  it "should have a valid factory" do
    expect(build(:workflow)).to be_valid
  end

  it "must belong to a project" do
    expect(build(:workflow, project: nil)).to_not be_valid
  end
end
