require 'spec_helper'

describe FieldGuide, type: :model do
  let(:field_guide) { build(:field_guide) }
  it "should have a valid factory" do
    expect(field_guide).to be_valid
  end
end
