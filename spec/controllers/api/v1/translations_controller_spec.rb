require 'spec_helper'

RSpec.describe Api::V1::TranslationsController, type: :controller do
  let(:authorized_user) { create(:user) }

  # TODO: expand to worklows, tutorials, field guides, etc
  %i(project).each do |resource_type|
    let(:resource) { create(:translation) }
    let(:api_resource_name) { "translations" }
    let(:api_resource_attributes) { %w(id strings language) }
    let(:api_resource_links) { %w(translated.project) }
    let(:scopes) { [ resource_type ] }

    describe "#index", :focus do
      it_behaves_like "is indexable" do
        let(:index_params) do
          resource
          # passing a translated id will filter the project resources
          # TODO: add this as a specific filteirng spec on owning resources
          # { translated_id: resource.translated_id, translated_type: resource_type.to_s }
          { translated_type: resource_type.to_s }
        end
        let(:n_visible) { 2 }
        # TODO: remove the setup for all the specs here...can we do this?
        let!(:private_resource) do
          create(:translation, translated: create(:private_project))
        end
      end
    end
  end
end
