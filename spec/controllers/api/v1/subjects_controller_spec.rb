require 'spec_helper'

describe Api::V1::SubjectsController, type: :controller do
  let!(:workflow) { create(:workflow_with_subject_sets) }
  let!(:subjects) { create_list(:set_member_subject, 20, subject_set: workflow.subject_sets.first) }
  let!(:user) { create(:user) }

  let(:scopes) { %w(subject) }
  let(:resource_class) { Subject }
  let(:project) { create(:project) }
  let(:authorized_user) { user }

  let(:api_resource_name) { "subjects" }
  let(:api_resource_attributes) do
    [ "id", "metadata", "locations", "zooniverse_id", "created_at", "updated_at"]
  end

  let(:api_resource_links) do
    [ "subjects.owner" ]
  end

  context "logged in user" do
    before(:each) do
      default_request user_id: user.id, scopes: scopes
    end
    describe "#index" do
      context "without random sort" do
        before(:each) do
          get :index
        end

        it "should return 200" do
          expect(response.status).to eq(200)
        end

        it "should return a page of 20 objects" do
          expect(json_response[api_resource_name].length).to eq(20)
        end

        it_behaves_like "an api response"
      end

      context "with random sort" do
        let(:api_resource_attributes) do
          [ "id", "metadata", "locations", "zooniverse_id", "classifications_count",
           "state", "set_member_subject_id", "created_at", "updated_at" ]
        end
        let(:api_resource_links) { [ "subjects.subject_set" ] }
        let(:request_params) { { sort: 'random', workflow_id: workflow.id.to_s } }
        let(:cellect_results) { cellect_results = subjects.take(10).map(&:id) }
        let!(:session) do
          request.session = { cellect_hosts: { workflow.id.to_s => 'example.com' } }
        end

        describe "testing the response" do

          before(:each) do
            allow(stubbed_cellect_connection).to receive(:get_subjects).and_return(cellect_results)
            get :index, request_params
          end

          it "should return 200" do
            get :index, request_params
            expect(response.status).to eq(200)
          end

          it 'should return a page of 10 objects' do
            get :index, request_params
            expect(json_response[api_resource_name].length).to eq(10)
          end

          it_behaves_like "an api response"
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

  describe "#create" do
    let(:test_attr) { :locations }
    let(:test_attr_value) do
      { "standard" => "http://test.host/imgs/marioface.jpg" }
    end
    
    let(:create_params) do
      {
       subjects: {
                  metadata: { cool_factor: 11 },
                  locations: { standard: "http://test.host/imgs/marioface.jpg" },
                  project_id: project.id
                 }
      }
    end

    it_behaves_like "is creatable"
  end
  
  describe "#destroy" do
    let(:resource) { create(:subject, owner: user) }

    it_behaves_like "is destructable"
  end
end
