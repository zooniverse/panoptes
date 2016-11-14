require 'spec_helper'

RSpec.describe Organization, type: :model do
  let(:organization) { build(:organization) }

  it "should have a valid factory" do
    expect(organization).to be_valid
  end

  it 'should require a primary language field to be set' do
    expect(build(:organization, primary_language: nil)).to_not be_valid
  end
end
