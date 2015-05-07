require 'spec_helper'


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
    [ "id", "metadata", "locations", "zooniverse_id", "created_at", "updated_at", "retired", "already_seen"]
  end
  let(:api_resource_links) { [ "subjects.project" ] }

  describe "#index" do
    let!(:queue) do
      create(:subject_queue,
             user: nil,
             workflow: workflow,
             set_member_subject_ids: subjects.map(&:id))
    end

    context "logged out user" do

      describe "filtering" do
        let(:filterable_resources) do
          create_list(:collection_with_subjects, 2).first.subjects
        end
        let(:expected_filtered_ids) { formated_string_ids(filterable_resources) }

        it_behaves_like 'has many filterable', :collections
      end

      context "without any sort" do
        before(:each) do
          get :index
        end

        it_behaves_like "an api response"

        it "should return 200" do
          expect(response.status).to eq(200)
        end

        it "should return a page of 2 objects" do
          expect(json_response[api_resource_name].length).to eq(2)
        end
      end

      context "a queued request" do
        let!(:subjects) { create_list(:set_member_subject, 2, subject_set: subject_set) }
        let(:request_params) { { sort: 'queued', workflow_id: workflow.id.to_s } }
        context "with queued subjects" do

          context "when firing the request before the test" do
            before(:each) do
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

          context 'when the queue is below minimum' do
            it 'should reload the queue' do
              expect(SubjectQueueWorker).to receive(:perform_async).with(workflow.id, nil)
              get :index, request_params
            end
          end

          context 'when the queue is not below minimum)' do
            let(:subjects) { create_list(:set_member_subject, 21) }
            it 'should reload the queue' do
              expect(SubjectQueueWorker).to_not receive(:perform_async)
              get :index, request_params
            end
          end
        end
      end
    end

    context "logged in user" do
      before(:each) do
        default_request user_id: user.id, scopes: scopes
      end

      context "with a migrated project subject", :disabled do
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
        let!(:subjects) { create_list(:set_member_subject, 2, subject_set: subject_set) }
        let(:request_params) { { sort: 'queued', workflow_id: workflow.id.to_s } }
        context "with queued subjects" do
          let!(:queue) do
            create(:subject_queue,
                   user: user,
                   workflow: workflow,
                   set_member_subject_ids: subjects.map(&:id))
          end


          before(:each) do
            get :index, request_params
          end

          it "should return 200" do
            expect(response.status).to eq(200)
          end

          it 'should return a page of 2 objects' do
            expect(json_response[api_resource_name].length).to eq(2)
          end

          it_behaves_like "an api response"

          context 'when the queue is below minimum' do
            it 'should reload the queue' do
              expect(SubjectQueueWorker).to receive(:perform_async).with(workflow.id, user.id)
              get :index, request_params
            end
          end

          context 'when the queue is not below minimum)' do
            let(:subjects) { create_list(:set_member_subject, 21) }
            it 'should reload the queue' do
              expect(SubjectQueueWorker).to_not receive(:perform_async)
              get :index, request_params
            end
          end
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

        context "without already queued subjects" do
          before(:each) do
            get :index, request_params
          end

          it 'should create the queue' do
            expect(SubjectQueue.find_by(user: user, workflow: workflow)).to_not be_nil
          end

          it 'should return 200' do
            expect(response.status).to eq(200)
          end

          it 'should return a page of 2 objects' do
            expect(json_response[api_resource_name].length).to eq(2)
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
    end
  end

  describe "#show" do
    let(:resource) { create(:subject) }

    it_behaves_like "is showable"
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
