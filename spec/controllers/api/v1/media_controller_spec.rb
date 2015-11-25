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
      create_list :medium, 2, linked: parent, content_type: content_type,
        type: "#{parent_name}_#{media_type.to_s.singularize}"
    end

    if actions.include? :index
      describe "#index" do
        context "when #{media_type} exists" do
          before(:each) do
            default_request user_id: authorized_user.id, scopes: scopes
            get :index, :"#{parent_name}_id" => parent.id, :media_name => media_type
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
            get :index, :"#{parent_name}_id" => parent.id, :media_name => media_type
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
            get :show, :"#{parent_name}_id" => parent.id, :media_name => media_type,
              :id => resources.first.id
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
            parent.send(media_type).destroy
            default_request user_id: authorized_user.id, scopes: scopes
            get :show, :"#{parent_name}_id" => parent.id, :media_name => media_type,
              :id => media_id
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
        let(:resource) { resources.first }

        before(:each) do
          stub_token(scopes: scopes, user_id: authorized_user.id)
          set_preconditions
          params = { :id => resource.id, :"#{parent_name}_id" => parent.id, :media_name => media_type }
          delete :destroy, params
        end

        it "should return 204" do
          expect(response).to have_http_status(:no_content)
        end

        it "should delete the resource" do
          expect{resource_class.find(resource.id)}.to raise_error(ActiveRecord::RecordNotFound)
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
          params.merge(:"#{parent_name}_id" => parent.id, :media_name => media_type)
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
          params.merge(:"#{parent_name}_id" => parent.id, :media_name => media_type)
        end

        it_behaves_like "is updatable"

        if media_type == :aggregations_export

          after(:each) do
            default_request scopes: scopes, user_id: authorized_user.id
            put :update, update_params
          end

          it 'should send an email' do
            expect(AggregationDataMailerWorker).to receive(:perform_async).with(resource.id)
          end

          context "when the update is not finished" do
            let(:metadata) { { metadata: { "state" => "uploading" } } }

            it 'should not send an email' do
              expect(AggregationDataMailerWorker).not_to receive(:perform_async)
            end
          end

          context "when aggregation media resource is missing" do
            let(:resource) { nil }

            it 'should not send an email', :aggreate_failures do
              expect(subject).not_to receive(:send_aggregation_ready_email)
              expect(AggregationDataMailerWorker).not_to receive(:perform_async)
            end
          end
        else
          it 'should not send an email' do
            expect(AggregationDataMailerWorker).not_to receive(:perform_async)
          end
        end
      end

    end

    if actions.include? :index
      describe "#index" do
        context "when #{media_type} exists" do
          before(:each) do
            default_request user_id: authorized_user.id, scopes: scopes
            get :index, :"#{parent_name}_id" => parent.id, :media_name => media_type
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
            default_request user_id: authorized_user.id, scopes: scopes
            get :index, :"#{parent_name}_id" => parent.id, :media_name => media_type
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
          params.merge(:"#{parent_name}_id" => parent.id, :media_name => media_type)
        end

        it_behaves_like "is creatable"

        it "should return the medium's put url" do
          default_request user_id: authorized_user.id, scopes: scopes
          post :create, create_params
          expect(json_response["media"][0]["src"]).to eq(new_resource.put_url)
        end

        describe "updates relationship" do
          before(:each) do
            default_request user_id: authorized_user.id, scopes: scopes
            post :create, create_params
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
          delete :destroy, :"#{parent_name}_id" => parent.id, media_name: media_type
        end

        it "should return 204" do
          expect(response).to have_http_status(:no_content)
        end

        it "should delete the resource" do
          expect{resource_class.find(resource.id)}.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe "parent resources" do
    let(:project) { create(:project, owner: authorized_user) }

    describe "parent is a workflow" do
      let(:parent) { create(:workflow, project: project) }

      it_behaves_like "has_many media", :workflow, :attached_images, %i(index create show destroy), 'image/jpeg'
    end

    describe "parent is a project" do
      let(:parent) { project }

      it_behaves_like "has_one media",  :project, :avatar, %i(create index destroy), "image/jpeg"
      it_behaves_like "has_one media",  :project, :background, %i(create index destroy), "image/jpeg"
      it_behaves_like "has_many media", :project, :attached_images, %i(index create show destroy), 'image/jpeg'
      it_behaves_like "has_one media", :project, :classifications_export, %i(index), 'text/csv'
      it_behaves_like "has_one media", :project, :subjects_export, %i(index), 'text/csv'
      it_behaves_like "has_one media", :project, :aggregations_export, %i(index update), 'application/x-gzip'

      describe "classifications_exports #index" do
        let!(:resources) do
          create_list :medium, 2, linked: parent, content_type: "text/csv",
            type: "project_classifications_export"
        end

        it 'should return 404 without an authorized_user' do
          default_request user_id: create(:user).id, scopes: scopes
          get :index, project_id: parent.id, media_name: "classifications_export"
          expect(response).to have_http_status(:not_found)
        end

        it 'should return 404 without a user' do
          get :index, project_id: parent.id, media_name: "classifications_export"
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
