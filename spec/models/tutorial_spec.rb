require 'spec_helper'

describe Tutorial, type: :model do
  let(:tutorial) { build(:tutorial) }

  it "should have a valid factory" do
    expect(tutorial).to be_valid
  end

  it_behaves_like "is translatable" do
    let(:model) { create :tutorial }
  end

  it_behaves_like "a versioned model" do
    let(:versioned_attribute) { "display_name" }
  end
end
