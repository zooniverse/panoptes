require 'spec_helper'

describe Api::V1::SubjectsController, type: :controller do
  let!(:workflow) { create(:workflow_with_subject_sets) }
  let!(:subject_set) { workflow.subject_sets.first }
  let!(:subjects) { create_list(:set_member_subject, 2, subject_set: subject_set) }
  let!(:user) { create(:user) }

  let(:scopes) { %w(subject) }
  let(:resource_class) { Subject }
  let(:authorized_user) { user }
  let(:project) { create(:project, owner: user) }

  let(:api_resource_name) { "subjects" }
  let(:api_resource_attributes) do
    [ "id", "metadata", "locations", "zooniverse_id", "created_at", "updated_at"]
  end
  let(:api_resource_links) { [ "subjects.owner" ] }

  context "logged in user" do
    before(:each) do
      default_request user_id: user.id, scopes: scopes
    end
    
    describe "#index" do
      context "without random sort" do
        before(:each) do
          get :index
        end

        context "subjects that use the SubjectSerializer" do
          let(:api_resource_attributes) do
            [ "id", "metadata", "locations", "zooniverse_id", "created_at", "updated_at"]
          end
          let(:api_resource_links) { [ "subjects.owner" ] }

          context "without random sort" do
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
        end
      end

      context "subjects that use the SetMemberSubjectSerializer" do
        let(:api_resource_attributes) do
          [ "id", "metadata", "locations", "zooniverse_id", "classifications_count",
           "state", "set_member_subject_id", "created_at", "updated_at" ]
        end
        let(:api_resource_links) { [ "subjects.subject_set" ] }

        context "with queued subjects" do
          let(:request_params) do
            { sort: 'queued', workflow_id: workflow.id.to_s }
          end
          
          let!(:ues) do
            create(:user_subject_queue, user: user,
                   workflow: workflow,
                   set_member_subject_ids: subjects.map(&:id))
          end

          before(:each) do
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
              { sort: 'queued' }
            end
            
            it 'should return 422' do
              expect(response.status).to eq(422)
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

        context "with random sort" do
          let(:request_params) { { sort: 'random', workflow_id: workflow.id.to_s } }
          let(:cellect_results) { subjects.take(2).map(&:id) }
          
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

            it 'should return a page of 2 objects' do
              get :index, request_params
              expect(json_response[api_resource_name].length).to eq(2)
            end

            it_behaves_like "an api response"

            context "without a workflow id" do
              let(:request_params) do
                { sort: 'random' }
              end
              
              it 'should return 422' do
                expect(response.status).to eq(422)
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
  end

  describe "#show" do
    let(:resource) { create(:subject) }
    
    it_behaves_like "is showable"
  end

  describe "#update" do
    let(:resource) { create(:subject, owner: user) }
    let(:test_attr) { :metadata }
    let(:test_attr_value) { { "interesting_data" => "Tested Collection" } }
    let(:update_params) do
      {
       subjects: {
                  metadata: {
                             interesting_data: "Tested Collection"
                            }
                 }
      }
    end

    it_behaves_like "is updatable"
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
                  links: {  
                          project: project.id
                         }
                 }
      }
    end

    it_behaves_like "is creatable"
  end

  describe "#destroy" do
    let(:resource) { create(:subject, owner: user) }

    it_behaves_like "is destructable"
  end

  describe "versioning" do
    let(:resource) { create(:subject, owner: user) }

    let(:update_block) do
      10.times do |n|
        resource.update!(metadata: { times: n })
      end
    end
    
    let(:resource_param) { :subject_id }
   
    it_behaves_like "a versioned resource"
  end
end
