require 'spec_helper'

RSpec.describe Api::V1::TranslationsController, type: :controller do
  let(:authorized_user) { create(:user) }

  # TODO: expand to worklows, tutorials, field guides, etc
  %i(project).each do |resource_type|
    let(:resource) { create(:translation) }
    let(:api_resource_name) { "translations" }
    let(:api_resource_attributes) { %w(id strings language) }
    let(:api_resource_links) { %w(translations.project) }
    let(:scopes) { %i(translation) }

    describe "#index" do
      it_behaves_like "is indexable" do
        let(:index_params) do
          resource
          { translated_type: resource_type.to_s }
        end
        let(:n_visible) { 1 }
        let(:private_resource) do
          create(:translation, translated: create(:private_project))
        end

        describe "filtering" do
          let(:filter_params) do
            { translated_id: resource.translated_id, translated_type: resource_type.to_s }
          end

          before(:each) do
            default_request scopes: scopes, user_id: authorized_user.id
            get :index, filter_params
          end

          it "should filter the translated parent scope" do
            create(:translation)
            expect(json_response[api_resource_name].length).to eq(1)
            expect(resource_ids).to match_array([resource.id])
          end
        end
      end
    end

    describe "#create" do
      let(:test_attr) { :language }
      let(:language) { "en-NZ"}
      let(:test_attr_value)  { language }
      let(:translated_resource) { create(resource_type) }
      let(:translated_resource) { create(resource_type) }
      let(:resource_class) { Translation }

      let(:create_params) do
        {
          translations: {
            strings: {
              title: "The frozen plant",
              description: "Bro, how icy is this plant?",
              introduction: "This project aims to find six of the coolest plants",
              workflow_description: "Is this field even used?",
              researcher_quote: "A really great project, you should help :)",
              urls: [
                {label: "Blrugh", url: "http://blog.example.com/"},
                {label: "Twits", url: "http://twitter.com/example"}
              ]
            },
            language: language
          },
          translated_id: translated_resource.id,
          translated_type: translated_resource.class.model_name.singular
        }
      end

      it_behaves_like "is creatable" do
        before do
          create(
            :access_control_list,
            resource: translated_resource,
            user_group: authorized_user.identity_group,
            roles: ["translator"]
          )
        end
      end
    end

    describe "#show", :focus do
      it_behaves_like "is showable" do
        let(:show_params) do
          { translated_type: resource_type.to_s }
        end
      end
    end
  end
end
