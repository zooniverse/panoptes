require 'spec_helper'

RSpec.describe Export, type: :model do
  let(:classification) { create(:classification) }
  let(:export) { build(:export, exportable: classification) }

  it 'should have a valid factory' do
    expect(export).to be_valid
  end

  it 'should not be valid without data' do
    invalid_data_msg = ["must be present but can be empty"]
    export.data = nil
    expect(export.valid?).to be false
    expect(export.errors[:data]).to match_array(invalid_data_msg)
  end

  it 'should not be valid without an exportable resource' do
    export.exportable = nil
    expect(export).to_not be_valid
  end
end
