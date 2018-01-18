require 'spec_helper'

RSpec.describe Api::V1::TranslationsController, type: :controller do
  let(:authorized_user) { create(:user) }

  # TODO: expand to worklows, tutorials, field guides, etc
  %i(project).each do |resource_type|
    let(:resource_class) { Translation }
    let(:translated_resource) { create(resource_type) }
    let(:resource) { create(:translation, translated: translated_resource) }
    let(:api_resource_name) { "translations" }
    let(:api_resource_attributes) { %w(id strings language) }
    let(:api_resource_links) { %w(translations.project) }
    let(:scopes) { %i(translation) }

    let(:user_translator_role) do
      create(
        :access_control_list,
        resource: translated_resource,
        user_group: authorized_user.identity_group,
        roles: ["translator"]
      )
    end

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
      let(:language) { "en-NZ" }
      let(:test_attr_value)  { language }

      let(:create_params) do
        {
          translations: {
            strings: {
              title: "The frozen plant",
              description: "Burr, how icy is this plant?",
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
          translated_type: resource_type
        }
      end

      it_behaves_like "is creatable" do
        before { user_translator_role }
      end
    end

    describe "#show" do
      let(:show_params) do
        { translated_type: resource_type.to_s }
      end

      it_behaves_like "is showable"

      context "with a private translated resource" do
        before(:each) do
          translated_resource.update_column(:private, true)
          default_request scopes: scopes, user_id: authorized_user.id
        end

        context "when the user has no roles" do
          before do
            get :show, show_params.merge(id: resource.id)
          end

          it 'should return 404' do
            expect(response.status).to eq 404
          end

          it "should return a specific error message in the response body" do
            not_found_msg = "Could not find #{resource_type} translations with id='#{resource.id}'"
            expect(response.body).to eq(json_error_message(not_found_msg))
          end
        end

        context "when the user has a translator role" do
          it 'should return 200' do
            user_translator_role
            get :show, show_params.merge(id: resource.id)
            expect(response.status).to eq 200
          end
        end
      end
    end

    describe "#update" do
      it_behaves_like "is updatable" do
        before { user_translator_role }

        let(:translation_strings) do
          {
            title: "Un buen proyecto",
            description: "Esto es increíble",
            introduction: "Este proyecto tiene como objetivo encontrar",
            workflow_description: "¿Se ha utilizado este campo?",
            researcher_quote: "Posiblemente el cuarto proyecto más grande jamás",
            urls: [
              {label: "Blog", url: "http://blog.example.com/"},
              {label: "El Gorjeo", url: "http://twitter.com/example"}
            ]
          }
        end
        let(:test_attr) { :strings }
        let(:test_attr_value)  { JSON.parse(translation_strings.to_json) }
        let(:update_params) do
          {
            translations: {
              strings: translation_strings
            },
            translated_type: resource_type.to_s
          }
        end
      end
    end
  end
end
