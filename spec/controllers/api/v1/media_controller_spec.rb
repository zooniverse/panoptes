require 'spec_helper'

RSpec.describe Api::V1::MediaController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:api_resource_name){ 'media' }
  let(:resource_class) { Medium }
  let(:api_resource_attributes) { %w(id src media_type content_type created_at href metadata) }
  let(:api_resource_links) { [] }
  let(:scopes) { %w(public medium) }

  RSpec.shared_examples "has_many media" do |parent_name, media_type, actions, content_type|
    let!(:resources) do
      create_list :medium, 2, linked: parent, content_type: content_type, type: "#{parent_name}_#{media_type.to_s.singularize}"
    end

    if actions.include? :index
      describe "#index" do
        context "when #{media_type} exists" do
          before(:each) do
            default_request user_id: authorized_user.id, scopes: scopes
            get :index, params: { "#{parent_name}_id": parent.id, media_name: media_type }
          end

          it 'should return ok' do
            expect(response).to have_http_status(:ok)
          end

          it 'should include 2 items' do
            expect(json_response["media"].length).to eq(2)
          end

          it_behaves_like "an api response"
        end

        context "when #{media_type} does not exist" do
          let!(:resources) { [] }

          before(:each) do
            parent.send(media_type).destroy
            default_request user_id: authorized_user.id, scopes: scopes
            get :index, params: { "#{parent_name}_id": parent.id, media_name: media_type }
          end

          it 'should return 404' do
            expect(response).to have_http_status(:not_found)
          end

          it 'should return an error message' do
            msg = json_response['errors'][0]['message']
            expect(msg).to match(/No #{media_type} exists for #{parent_name} ##{parent.id}/)
          end
        end
      end
    end

    if actions.include? :show
      describe "#show" do
        context "when #{media_type} exists" do
          before(:each) do
            default_request user_id: authorized_user.id, scopes: scopes
            get :show, params: { "#{parent_name}_id": parent.id, media_name: media_type,
                                 id: resources.first.id }
          end

          it 'should return ok' do
            expect(response).to have_http_status(:ok)
          end

          it 'should include 1 item' do
            expect(json_response["media"].length).to eq(1)
          end

          it_behaves_like "an api response"
        end

        context "when #{media_type} does not exist" do
          let(:media_id) {(Medium.last.id + 100)}
          before(:each) do
            default_request user_id: authorized_user.id, scopes: scopes
            get :show, params: { "#{parent_name}_id": parent.id, media_name: media_type,
                                 id: media_id }
          end

          it 'should return 404' do
            expect(response).to have_http_status(:not_found)
          end

          it 'should return an error message' do
            msg = json_response['errors'][0]['message']
            expect(msg).to match(/No #{media_type} ##{media_id} exists for #{parent_name} ##{parent.id}/)
          end
        end
      end
    end

    if actions.include? :destroy
      describe "#destroy" do
        before(:each) do
          stub_token(scopes: scopes, user_id: authorized_user.id)
          set_preconditions
        end
        let(:resource) { resources.first }
        let(:params) do
          { id: resource.id, "#{parent_name}_id": parent.id, media_name: media_type, test: 1 }
        end
        let(:destroy_action) do
          delete :destroy, params: params
        end

        it "should return 204" do
          destroy_action
          expect(response).to have_http_status(:no_content)
        end

        it "should delete the resource" do
          destroy_action
          expect{resource_class.find(resource.id)}.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "should raise an error when attempting to delete the wrong resource type" do
          parent_scope = parent.class.where(id: parent.id)
          allow(controller).to receive(:controlled_resources).and_return(parent_scope)
          expect{ destroy_action }.to raise_error(
            JsonApiController::DestructableResource::IncorrectClass,
            "Attempting to delete the wrong resource type - #{parent.class.name}"
          )
        end
      end
    end

    if actions.include? :create
      describe "#create" do
        let!(:resource) { parent.send(media_type) }
        let(:resource_url) { "http://test.host/api/#{parent_name}s/#{parent.id}/#{media_type}/#{json_response["media"][0]["id"]}" }
        let(:test_attr) { :type }
        let(:test_attr_value) { "#{parent_name}_#{media_type.to_s.singularize}" }
        let(:new_resource) { resource_class.find(created_instance_id(api_resource_name)) }
        let(:create_params) do
          params = {
                    media: {
                            content_type: content_type,
                            metadata: { filename: "image.png" }
                           }
                   }
          params.merge("#{parent_name}_id": parent.id, media_name: media_type)
        end

        it_behaves_like "is creatable"
      end
    end
  end

  RSpec.shared_examples "has_one media" do |parent_name, media_type, actions, content_type|
    let!(:resource) do
      create(:medium, linked: parent, type: "#{parent_name}_#{media_type}", content_type: content_type)
    end

    if actions.include? :update
      describe "#update" do
        let(:test_attr) { :metadata }
        let(:test_attr_value) { { "state" => "ready" } }
        let(:metadata) { { metadata: { "state" => "ready" } } }
        let(:update_params) do
          params = { media: metadata }
          params.merge("#{parent_name}_id": parent.id, media_name: media_type)
        end

        it_behaves_like "is updatable"
      end
    end

    if actions.include? :index
      describe "#index" do
        let(:get_index) do
          default_request user_id: authorized_user.id, scopes: scopes
          get :index, params: { "#{parent_name}_id": parent.id, media_name: media_type }
        end

        context "when #{media_type} exists" do
          before(:each) do
            get_index
          end

          it 'should return ok' do
            expect(response).to have_http_status(:ok)
          end

          it 'should include 1 item' do
            expect(json_response["media"].length).to eq(1)
          end

          it_behaves_like "an api response"
        end

        context "when #{media_type} does not exist" do
          before(:each) do
            resource.destroy
            get_index
          end

          it 'should return 404' do
            expect(response).to have_http_status(:not_found)
          end

          it 'should return an error message' do
            msg = json_response['errors'][0]['message']
            expect(msg).to match(/No #{media_type} exists for #{parent_name} ##{parent.id}/)
          end
        end

        context "when another media type exits" do
          before do
            create(:medium, linked: parent, type: "another_media_type", content_type: "image/jpeg")
            get_index
          end

          it 'should return ok' do
            expect(response).to have_http_status(:ok)
          end

          it 'should include only the requested media type item' do
            expect(json_response["media"].length).to eq(1)
            expect(json_response["media"][0]["media_type"]).to eq("#{parent_name}_#{media_type}")
          end
        end
      end
    end

    if actions.include? :create
      describe "#create" do
        let(:resource_url) { "http://test.host/api/#{parent_name}s/#{parent.id}/#{media_type}" }
        let(:test_attr) { :type }
        let(:test_attr_value) { "#{parent_name}_#{media_type}" }
        let(:new_resource) { resource_class.find(created_instance_id(api_resource_name)) }
        let(:create_params) do
          params = {
            media: {
              content_type: "image/jpeg",
              metadata: { filename: "image.png" }
            }
          }
          params.merge("#{parent_name}_id": parent.id, media_name: media_type)
        end

        it_behaves_like "is creatable"

        it "should return the medium's put url" do
          default_request user_id: authorized_user.id, scopes: scopes
          post :create, params: create_params
          expect(json_response["media"][0]["src"]).to eq(new_resource.put_url)
        end

        describe 'uploading externally hosted media resources' do
          let(:external_media_payload) do
            {
              media: {
                content_type: "image/jpeg",
                external_link: true,
                src: 'https://example.com/test.jpeg',
                metadata: { filename: "image.png" }
              },
              "#{parent_name}_id": parent.id,
              media_name: media_type
            }
          end

          it "should create an externally hosted media resource" do
            default_request user_id: authorized_user.id, scopes: scopes
            post :create, params: external_media_payload
            media_location = json_response["media"][0]["src"]
            expect(media_location).to eq(
              external_media_payload.dig(:media, :src)
            )
          end
        end

        describe "updates relationship" do
          before(:each) do
            default_request user_id: authorized_user.id, scopes: scopes
            post :create, params: create_params
          end

          it "should replace the old #{media_type}" do
            parent.reload
            expect(parent.send(media_type)).to eq(new_resource)
          end

          it "should destroy the old #{media_type}" do
            expect{ resource.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    if actions.include? :destroy
      describe "#destroy" do
        before(:each) do
          stub_token(scopes: scopes, user_id: authorized_user.id)
          set_preconditions
        end
        let(:destroy_action) do
          delete :destroy, params: { "#{parent_name}_id" => parent.id, media_name: media_type }
        end

        it "should return 204" do
          destroy_action
          expect(response).to have_http_status(:no_content)
        end

        it "should delete the resource" do
          destroy_action
          expect{resource_class.find(resource.id)}.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "should raise an error when attempting to delete the wrong resource type" do
          allow(controller)
            .to receive(:controlled_resources)
            .and_return(parent.class.where(id: parent.id))

          expect{ destroy_action }.to raise_error(
            JsonApiController::DestructableResource::IncorrectClass,
            "Attempting to delete the wrong resource type - #{parent.class.name}"
          )
        end
      end
    end
  end

  describe "parent resources" do
    let(:project) { create(:project, owner: authorized_user) }

    describe "parent is a workflow" do
      let(:parent) { create(:workflow, project: project) }

      it_behaves_like "has_many media", :workflow, :attached_images, %i(index create show destroy), 'image/jpeg'
      it_behaves_like "has_one media", :workflow, :classifications_export, %i(index), 'text/csv'

      describe "classifications_exports #index" do
        let!(:resources) do
          create(:medium, linked: parent, type: "workflow_classifications_export", content_type: "text/csv")
        end

        it 'should return 404 without an authorized_user' do
          default_request user_id: create(:user).id, scopes: scopes
          get :index, params: { project_id: parent.id, media_name: 'classifications_export' }
          expect(response).to have_http_status(:not_found)
        end

        it 'should return 404 without a user' do
          get :index, params: { project_id: parent.id, media_name: 'classifications_export' }
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "parent is a project" do
      let(:parent) { project }

      it_behaves_like "has_one media",  :project, :avatar, %i(create index destroy), "image/jpeg"
      it_behaves_like "has_one media",  :project, :background, %i(create index destroy), "image/jpeg"
      it_behaves_like "has_many media", :project, :attached_images, %i(index create show destroy), 'image/jpeg'
      it_behaves_like "has_one media", :project, :classifications_export, %i(index), 'text/csv'
      it_behaves_like "has_one media", :project, :subjects_export, %i(index), 'text/csv'

      describe "classifications_exports #index" do
        let!(:resources) do
          create(:medium, linked: parent, type: "project_classifications_export", content_type: "text/csv")
        end

        it 'should return 404 without an authorized_user' do
          default_request user_id: create(:user).id, scopes: scopes
          get :index, params: { project_id: parent.id, media_name: 'classifications_export' }
          expect(response).to have_http_status(:not_found)
        end

        it 'should return 404 without a user' do
          get :index, params: { project_id: parent.id, media_name: 'classifications_export' }
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "parent is a user" do
      let(:parent) { authorized_user }

      it_behaves_like "has_one media", :user, :avatar, %i(create index destroy), "image/jpeg"
      it_behaves_like "has_one media", :user, :profile_header, %i(create index destroy), "image/jpeg"
    end

    describe "parent is a tutorial" do
      let(:parent) { create(:tutorial, project: project) }

      it_behaves_like "has_many media", :tutorial, :attached_images, %i(index create show destroy), 'image/jpeg'
    end

    describe "parent is a field_guide" do
      let(:parent) { create(:field_guide, project: project) }

      it_behaves_like "has_many media", :field_guide, :attached_images, %i(index create show destroy), 'image/jpeg'
    end
  end
end
