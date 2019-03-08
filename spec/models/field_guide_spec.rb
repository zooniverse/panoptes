require 'spec_helper'

describe FieldGuide, type: :model do
  let(:field_guide) { build(:field_guide) }

  it_behaves_like "a versioned model" do
    let(:new_value) { [{"version" => "two"}] }
  end

  it "should have a valid factory" do
    expect(field_guide).to be_valid
  end

  it_behaves_like "is translatable" do
    let(:model) { create :field_guide }
  end
end
