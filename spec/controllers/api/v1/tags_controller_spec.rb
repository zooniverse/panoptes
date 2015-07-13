require 'spec_helper'

RSpec.describe Api::V1::TagsController, type: :controller do
  let!(:tags) { create_list(:tag, 2) }

  let(:scopes) { %w(public) }

  let(:api_resource_name) { "tags" }
  let(:api_resource_attributes) do
    ["name", "popularity"]
  end

  let(:api_resource_links) { [] }

  let(:authorized_user) { create(:user) }

  let(:resource) { tags.first }
  let(:resource_class) { Tag }

  describe "#index" do
    let(:n_visible) { 2 }

    it_behaves_like "is indexable", false
  end

  describe "#show" do
    it_behaves_like "is showable"
  end
end
