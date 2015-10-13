require 'spec_helper'

describe Tutorial, type: :model do
  let(:tutorial) { build(:tutorial) }
  it "should have a valid factory" do
    expect(tutorial).to be_valid
  end
end
