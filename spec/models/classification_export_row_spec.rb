require 'spec_helper'

RSpec.describe ClassificationExportRow, type: :model do
  let(:classification) { create(:classification) }
  let(:export_row) do
    build(:classification_export_row) do |export_row|
      # set the data attributes here...
      # export_row.
    end
  end

  it 'should have a valid factory' do
    expect(export_row).to be_valid
  end

  it 'should not be valid without a classification' do
    export_row.classification = nil
    expect(export_row).to_not be_valid
  end

  it 'should not be valid without data' do
    invalid_data_msg = ["must be present but can be empty"]
    export_row.data = nil
    expect(export_row.valid?).to be false
    expect(export_row.errors[:data]).to match_array(invalid_data_msg)
  end

  describe "::create_from_classification", :focus do
    it 'should create a classification_export_row' do
      expect {
        ClassificationExportRow.create_from_classification(classification)
      }.to change {
        binding.pry
        ClassificationExportRow.where(
          project: classification.project,
          classification: classification
        ).count
      }.by(1)
    end
  end
end
