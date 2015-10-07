require 'spec_helper'

describe Tutorial, type: :model do
  let(:tutorial) { build(:tutorial) }
  it "should have a valid factory" do
    expect(tutorial).to be_valid
  end

  it "should validate the format of the steps array" do
    tutorial.steps = [{titel: "asomething", context: "test"}]
    aggregate_failures "validation" do
      expect(tutorial).to_not be_valid
      expect(tutorial.errors).to include(:"steps.0.title", :"steps.0.content")
    end
  end
end
