require 'spec_helper'

RSpec.describe Translation, type: :model do
  let(:translation) { create(:translation) }

  it 'should have a valid factory' do
    expect(translation).to be_valid
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
    let(:expected_model_name) do
      [ Project.model_name ]
    end

    it "should list all the model names that have translation resources" do
      expect(Translation.translated_model_names).to match_array(expected_model_name)
    end
  end
end
