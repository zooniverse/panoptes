require 'spec_helper'

describe GoldStandardAnnotationSerializer do
  let(:gsa) { create(:gold_standard_annotation) }

  it_should_behave_like "a panoptes restpack serializer" do
    let(:resource) { gsa }
    let(:includes) { [:project, :user, :workflow] }
    let(:preloads) { [ ] }
  end

  it_should_behave_like "a no count serializer" do
    let(:resource) { gsa }
  end

  describe "nested collection routes" do
    before do
      gsa
    end

    it "should return the correct href urls" do
      collection_route = "gold_standard"
      context = {url_suffix: collection_route}
      result = described_class.page({}, GoldStandardAnnotation.all, context)
      meta = result[:meta][:classifications]
      expect(meta[:first_href]).to eq("/classifications/#{collection_route}")
      expect(meta[:previous_href]).to eq("/classifications/#{collection_route}?page=0")
      expect(meta[:next_href]).to eq("/classifications/#{collection_route}?page=2")
      expect(meta[:last_href]).to eq("/classifications/#{collection_route}?page=0")
    end
  end
end
