require 'spec_helper'

UUIDv4Regex = /[a-f0-9]{8}\-[a-f0-9]{4}\-4[a-f0-9]{3}\-(8|9|a|b)[a-f0-9]{3}\-[a-f0-9]{12}/

describe Api::V1::SubjectsController, type: :controller do
  let!(:workflow) { create(:workflow_with_subject_sets) }
  let!(:subject_set) { workflow.subject_sets.first }
  let!(:subjects) { create_list(:set_member_subject, 2, subject_set: subject_set).map(&:subject) }
  let!(:user) { create(:user) }

  let(:scopes) { %w(subject) }
  let(:resource_class) { Subject }
  let(:authorized_user) { user }
  let(:project) { create(:project, owner: user) }

  let(:api_resource_name) { "subjects" }
  let(:api_resource_attributes) do
    [ "id", "metadata", "locations", "zooniverse_id", "created_at", "updated_at"]
  end
  let(:api_resource_links) { [ "subjects.project" ] }

  context "logged in user" do
    before(:each) do
      default_request user_id: user.id, scopes: scopes
    end

    describe "#index" do

      context "with a migrated project subject" do
        let!(:migrated_subject) { create(:migrated_project_subject) }

        before(:each) do
          get :index
        end

        it "should return 200" do
          expect(response.status).to eq(200)
        end

        it "should return a page of 2 objects" do
          expect(json_response[api_resource_name].length).to eq(3)
        end

        it_behaves_like "an api response"
      end

      context "without any sort" do
        before(:each) do
          get :index
        end

        it "should return 200" do
          expect(response.status).to eq(200)
        end

        it "should return a page of 2 objects" do
          expect(json_response[api_resource_name].length).to eq(2)
        end

        it_behaves_like "an api response"
      end

      context "a queued request" do
        let(:request_params) { { sort: 'queued', workflow_id: workflow.id.to_s } }

        context "with queued subjects" do
          before(:each) do
            create(:user_subject_queue,
                   user: user,
                   workflow: workflow,
                   subject_ids: subjects.map(&:id))
            get :index, request_params
          end

          it "should return 200" do
            expect(response.status).to eq(200)
          end

          it 'should return a page of 2 objects' do
            expect(json_response[api_resource_name].length).to eq(2)
          end

          it_behaves_like "an api response"
        end

        context "without a workflow id" do
          before(:each) do
            get :index, request_params
          end

          let(:request_params) do
            { sort: 'queued' }
          end

          it 'should return 422' do
            expect(response.status).to eq(422)
          end
        end

        context "without queued subejcts" do
          before(:each) do
            get :index, request_params
          end

          it 'should return 404' do
            expect(response.status).to eq(404)
          end
        end
      end

      context "with subject_set_ids" do
        let(:request_params) { { subject_set_id: subject_set.id.to_s } }

        before(:each) do
          get :index, request_params
        end

        it "should return 200" do
          expect(response.status).to eq(200)
        end

        it 'should return a page of 2 objects' do
          get :index, request_params
          expect(json_response[api_resource_name].length).to eq(2)
        end

        it_behaves_like "an api response"
      end

      context "with cellect sort" do
        let(:request_params) do
          { sort: 'cellect', workflow_id: workflow.id.to_s }
        end
        let(:cellect_results) { subjects.take(2).map(&:id) }

        describe "testing the response" do

          before(:each) do
            allow(stubbed_cellect_connection).to receive(:get_subjects).and_return(cellect_results)
            get :index, request_params
          end

          it "should return 200" do
            get :index, request_params
            expect(response.status).to eq(200)
          end

          it 'should return a page of 2 objects' do
            get :index, request_params
            expect(json_response[api_resource_name].length).to eq(2)
          end

          it_behaves_like "an api response"

          context "without a workflow id" do
            let(:request_params) do
              { sort: 'cellect' }
            end

            it 'should return 422' do
              expect(response.status).to eq(422)
            end
          end

          context "when no per_page size is specified" do

            it "should set the page_size param to 10" do
              response_page_size = json_response["meta"][api_resource_name]["page_size"]
              expect(response_page_size).to eq(10)
            end
          end
        end

        describe "testing the cellect client setup" do
          it 'should make a request against Cellect' do
            expect(stubbed_cellect_connection).to receive(:get_subjects).and_return(cellect_results)
            get :index, request_params
          end
        end
      end
    end
  end

  describe "#show" do
    let(:resource) { create(:subject) }

    it_behaves_like "is showable"

    context "location urls" do
      let(:url) { json_response['subjects'][0]['locations'][0]['image/jpeg'] }

      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
        get :show, id: resource.id
      end

      it 'should return the location path as an id' do
        expect(url).to match(/https:\/\/panoptes-uploads.zooniverse.org/)
      end

      it 'should return the uuid file name' do
        expect(url).to match(UUIDv4Regex)
      end
    end
  end

  describe "#update" do
    let(:resource) { create(:subject, project: create(:project, owner: user)) }
    let(:test_attr) { :metadata }
    let(:test_attr_value) do
      {
        "interesting_data" => "Tested Collection",
        "an_interesting_array" => ["1", "2", "asdf", "99.99"]
      }
    end
    let(:update_params) do
      {
        subjects: {
          metadata: {
            interesting_data: "Tested Collection",
            an_interesting_array: ["1", "2", "asdf", "99.99"]
          },
          locations: [ "image/jpeg" ]
        }
      }
    end

    it_behaves_like "is updatable"
  end

  describe "#create" do
    let(:test_attr) { :metadata }
    let(:test_attr_value) do
      { "cool_factor" => "11" }
    end

    let(:create_params) do
      {
        subjects: {
          metadata: { cool_factor: "11" },
          locations: ["image/jpeg", "image/jpeg", "image/jpeg"],
          links: {
            project: project.id
          }
        }
      }
    end

    context "s3 urls" do
      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, create_params
      end

      let(:standard_url) do
        json_response['subjects'][0]['locations'][0]['image/jpeg']
      end

      it 'should return locations as a hash of signed s3 urls' do
        expect(standard_url).to match(/Expires=[0-9]+&Signature=[%A-z0-9]+/)
      end

      it "should set a uuidv4 id as the file name" do
        expect(standard_url).to match(UUIDv4Regex)
      end

      it "should set the file extension from the provided mime-type" do
        expect(standard_url).to match(/\.jpeg/)
      end

      it "should set the bucket with a path prefix" do
        expect(standard_url).to match(/s3_subject_bucket\/test_bucket_path/)
      end
    end

    context "when the user is not-the owner of the project" do
      let(:unauthorised_user) { create(:user) }

      before(:each) do
        default_request scopes: scopes, user_id: unauthorised_user.id
        post :create, create_params
      end

      it 'should return unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should scrub any schema sql from the error message' do
        expect(response.body).to eq(json_error_message("Couldn't find linked project for current user"))
      end
    end

    context "when the project is owned by the user" do
      it_behaves_like "is creatable"
    end

    context "when the project is owned by a user_group the user may edit" do
      let(:membership) { create(:membership, state: 0, roles: ["project_editor"]) }
      let(:project) { create(:project, owner: membership.user_group) }
      let(:authorized_user) { membership.user }

      it_behaves_like "is creatable"
    end
  end

  describe "#destroy" do
    let(:resource) { create(:subject, project: create(:project, owner: user)) }

    it_behaves_like "is destructable"
  end

  describe "versioning" do
    let(:resource) { create(:subject, project: create(:project, owner: user)) }
    let!(:existing_versions) { resource.versions.length }
    let(:num_times) { 10 }
    let(:update_proc) do
      Proc.new { |resource, n| resource.update!(metadata: { times: n }) }
    end
    let(:resource_param) { :subject_id }

    it_behaves_like "a versioned resource"
  end
end
