# frozen_string_literal: true

require 'spec_helper'

describe RecentSerializer do
  let(:recent) { create(:recent) }
  let(:prefix) { "users/1" }
  let(:context) do
    { url_prefix: prefix }
  end

  it_behaves_like 'a panoptes restpack serializer' do
    let(:resource) { recent }
    let(:includes) { [] }
    let(:preloads) { [:locations] }
  end

  it_behaves_like 'a no count serializer' do
    let(:resource) { recent }
  end

  describe "#locations" do
    let!(:recent) { create(:recent) }
    let(:result_locs) do
      RecentSerializer.single({}, Recent.all, context)[:locations]
    end

    it "should use the subject ordered locations method" do
      expect_any_instance_of(Recent)
        .to receive(:ordered_locations)
        .and_call_original
      result_locs
    end

    it "should serialize the locations into a mime : url hash" do
      expected = recent.subject.ordered_locations.map do |loc|
        { :"#{loc.content_type}" => loc.url_for_format(:get) }
      end
      expect(expected).to match_array(result_locs)
    end
  end

  describe "#href" do
    it "should include the url_prefix for the resource route" do
      recent = create(:recent)
      result = RecentSerializer.single({}, Recent.all, context)
      expect(result[:href]).to eq("/#{prefix}/recents/#{recent.id}")
    end
  end

  describe "meta paging urls" do
    it "should return the correct href urls" do
      result = RecentSerializer.page({}, Recent.all, context)
      meta = result[:meta][:recents]
      expect(meta[:first_href]).to eq("/#{prefix}/recents")
      expect(meta[:last_href]).to eq("/#{prefix}/recents?page=0")
    end
  end
end
