require 'spec_helper'

RSpec.describe Api::V1::TranslationsController, type: :controller do
  let(:authorized_user) { create(:user) }

  # TODO: expand to worklows, tutorials, field guides, etc
  %i(project).each do |resource_type|
    let(:resource_class) { Translation }
    let(:translated_resource) { create(resource_type) }
    let(:resource) do
      create(:translation, language: 'es', translated: translated_resource)
    end
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

    shared_examples "it does not allow primary language payloads" do
      let(:resource) do
        create(:translation, translated: translated_resource)
      end

      context "with a translator role" do
        before { user_translator_role }

        it "it should not allow changes to primary language translations" do
          run_request
          expect(response).to have_http_status(:not_found)
        end
      end

      context "with an owner role" do
        let(:authorized_user) { translated_resource.owner }

        it "it should not allow changes to primary language translations" do
          run_request
          expect(response).to have_http_status(:not_found)
        end
      end
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
          let(:non_filter_translation) do
            create(:translation, language: "en-AU")
          end

          before(:each) do
            non_filter_translation
            default_request scopes: scopes, user_id: authorized_user.id
            get :index, params: filter_params
          end

          describe "filtering on translation resources" do
            let(:filter_params) do
              { translated_id: resource.translated_id, translated_type: resource_type.to_s }
            end

            it "should return the filtered resource only" do
              expect(json_response[api_resource_name].length).to eq(1)
              expect(resource_ids).to match_array([resource.id])
            end
          end

          describe "filtering on language code" do
            let(:filter_params) do
              { language: resource.language.upcase, translated_type: resource_type.to_s }
            end

            it "should return the filtered resource only" do
              expect(json_response[api_resource_name].length).to eq(1)
              expect(resource_ids).to match_array([resource.id])
            end
          end
        end
      end
    end

    describe "#create" do
      let(:test_attr) { :language }
      let(:language) { "en-NZ" }
      let(:test_attr_value)  { language.downcase }

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

      it_behaves_like "it does not allow primary language payloads" do
        let(:language) { translated_resource.primary_language }
        let(:run_request) do
          default_request scopes: scopes, user_id: authorized_user.id
          post :create, params: create_params
        end
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
            get :show, params: show_params.merge(id: resource.id)
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
            get :show, params: show_params.merge(id: resource.id)
            expect(response.status).to eq 200
          end
        end
      end
    end

    describe "#update" do
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
      let(:update_params) do
        {
          translations: {
            strings: translation_strings
          },
          translated_type: resource_type.to_s
        }
      end

      it_behaves_like "is updatable" do
        before { user_translator_role }
        let(:test_attr) { :strings }
        let(:test_attr_value)  { JSON.parse(translation_strings.to_json) }
      end

      it_behaves_like "it does not allow primary language payloads" do
        let(:run_request) do
          default_request scopes: scopes, user_id: authorized_user.id
          params = update_params.merge(id: resource.id)
          put :update, params: params
        end
      end
    end
  end
end
