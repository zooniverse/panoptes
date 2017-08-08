require 'spec_helper'

describe TranslationSerializer do
  let(:translation) { create(:translation) }

  it_should_behave_like "a panoptes restpack serializer" do
    let(:resource) { translation }
    let(:includes) { [] }
    let(:preloads) { [] }
  end

  describe "filtering" do
    before do
      translation
    end
    let(:serialized_result) { described_class.page(filter, Translation.all) }
    let(:filtered_resources) { serialized_result[:translations] }
    let(:filtered_ids) { filtered_resources.map { |p| p[:id] } }

    context "language" do
      let(:lang_code) { "en-AU"}
      let(:filtered_translation) { create(:translation, language: lang_code) }
      let(:filter) { { language: lang_code } }

      it "should filter on language codes" do
        filtered_translation
        expect(filtered_ids).to match_array([filtered_translation.id.to_s])
        expect(filtered_resources.count).to eq(1)
      end
    end
  end
end
