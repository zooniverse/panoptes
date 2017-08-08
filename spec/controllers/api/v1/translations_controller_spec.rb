require 'spec_helper'

RSpec.describe Api::V1::TranslationsController, type: :controller do
  let(:authorized_user) { create(:user) }

  # TODO: expand to worklows, tutorials, field guides, etc
  %i(project).each do |resource_type|
    let(:resource) { create(resource_type) }
    let(:api_resource_name) { "#{resource_type}" }
    let(:api_resource_attributes) { %w(id strings language) }
    let(:api_resource_links) { %w(workflow_contents.workflow) }
    let(:scopes) { [ resource_type ] }

    describe "#index", :focus do
      let!(:private_resource) do
        create(resource_type, private: true)
      end

      let(:n_visible) { 2 }

      it_behaves_like "is indexable"
    end
  end
end
