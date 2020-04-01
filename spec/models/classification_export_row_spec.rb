require 'spec_helper'

RSpec.describe ClassificationExportRow, type: :model do
  let(:classification) { create(:classification) }
  let(:export_row) do
    build(:classification_export_row, classification: classification)
  end

  it 'should have a valid factory', :focus do
    expect(export_row).to be_valid
  end

  it 'should not be valid without a classification' do
    export_row.classification = nil
    expect(export_row).to_not be_valid
  end

  it 'should not be valid without attributes' do
    error_msg = [ "can't be blank" ]
    attributes = %i(workflow_name workflow_version classification_created_at metadata annotations subject_data subject_ids)
    attributes.each do |attribute|
      export_row.send("#{attribute}=", nil)
      expect(export_row.valid?).to be false
      expect(export_row.errors[attribute]).to match_array(error_msg)
    end
  end
end
