require 'spec_helper'

RSpec.describe Translation, type: :model do
  let(:translation) { build(:translation) }

  it 'should have a valid factory' do
    expect(translation).to be_valid
  end

  it 'should downcase the language code before validation' do
    expect(translation.language).to eq("en-GB")
    translation.valid?
    expect(translation.language).to eq("en-gb")
  end

  it 'should not allow duplicate translations for a resource' do
    translation.save
    dup_translation = build(:translation, translated: translation.translated)
    expect(dup_translation).not_to be_valid
    expected_errors = ["Language translation already exists for this resource"]
    expect(dup_translation.errors).to match_array(expected_errors)
  end

  it 'should not be valid without strings' do
    invalid_strings_msg = ["must be present but can be empty"]
    translation.strings = nil
    expect(translation.valid?).to be false
    expect(translation.errors[:strings]).to match_array(invalid_strings_msg)
  end

  it 'should not be valid without a translated resource' do
    translation.translated = nil
    expect(translation).to_not be_valid
  end

  it 'should not be valid without a langague code' do
    translation.language = nil
    expect(translation).to_not be_valid
  end

  describe ".translated_model_names" do
    let(:expected_model_names) do
      %w(
        project
        project_page
        organization
        organization_page
        field_guide
        tutorial
        workflow
      )
    end

    it "should list all the model names that have translation resources" do
      expect(Translation.translated_model_names).to match_array(expected_model_names)
    end
  end

  describe '#outdated_strings' do
    it 'returns empty array if translation is in the primary language' do
      translation.save!
      expect(translation.outdated_strings).to be_empty
    end

    it 'returns diff' do
      translation.save!
      other = build(:translation)
      expect()
    end
  end
end
