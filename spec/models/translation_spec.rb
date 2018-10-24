require 'spec_helper'

RSpec.describe Translation, type: :model do
  let(:translation) { build(:translation, language: 'en-GB') }

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
    dup_translation = build(:translation, translated: translation.translated, language: 'en-gb')
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

  it 'should not be valid without string_versions' do
    invalid_msg = ["must be present but can be empty"]
    translation.string_versions = nil
    expect(translation.valid?).to be false
    expect(translation.errors[:string_versions]).to match_array(invalid_msg)
  end

  it 'should not be valid when referencing an unknown version' do
    invalid_msg = ["references unknown versions: 1, 2"]
    translation.strings = {foo: "Foo", bar: "Bar"}
    translation.string_versions = {foo: 1, bar: 2}
    expect(translation.valid?).to be false
    expect(translation.errors[:string_versions]).to match_array(invalid_msg)
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

  describe "#update_strings_and_versions" do
    it 'adds keys' do
      translation = build :translation, strings: {}, string_versions: {}
      translation.update_strings_and_versions({title: "Foo"}, 123)
      expect(translation.strings).to eq({"title" => "Foo"})
      expect(translation.string_versions).to eq({"title" => 123})
    end

    it 'updates keys' do
      translation = build :translation, strings: {title: "Foo"}, string_versions: {title: 1}
      translation.update_strings_and_versions({title: "Bar"}, 123)
      expect(translation.strings).to eq({"title" => "Bar"})
      expect(translation.string_versions).to eq({"title" => 123})
    end

    it 'leaves unchanged strings at their version' do
      translation = build :translation, strings: {title: "Foo"}, string_versions: {title: 1}
      translation.update_strings_and_versions({title: "Foo", description: "Bar"}, 123)
      expect(translation.strings).to eq({"title" => "Foo", "description" => "Bar"})
      expect(translation.string_versions).to eq({"title" => 1, "description" => 123})

    end

    it 'removes keys' do
      translation = build :translation, strings: {title: "Foo", description: "Bar"}, string_versions: {title: 1, description: 1}
      translation.update_strings_and_versions({title: "Foo"}, 123)
      expect(translation.strings).to eq({"title" => "Foo"})
      expect(translation.string_versions).to eq({"title" => 1})
    end
  end
end
