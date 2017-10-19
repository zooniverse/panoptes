require 'spec_helper'

RSpec.describe Export, type: :model do
  let(:classification) { create(:classification) }

  describe "association validations", :focus do
    let(:export) { build(:export, exportable: classification) }

    it 'should not be valid without a classification' do
      export.classification = nil
      expect(export).to_not be_valid
    end

    it 'should not be valid without a project' do
      export.subject = nil
      expect(export).to_not be_valid
    end
  end

  describe "::create_from_classification" do
    it 'should create an export for each from the classification' do
      export = Export.create_from_classification(classification)
      expect(export.data).to_match([])
    end
  end
end
