require 'spec_helper'

def annotation_values
  [ { key: "age", value: "adult" },
   { started_at: DateTime.now },
   { finished_at: DateTime.now },
   { user_agent: "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0" } ]
end

def setup_create_request(project_id, workflow_id, set_member_subject)
  request.session = { cellect_hosts: { workflow_id.to_s => "example.com" } }
  params =
    {
     classifications: {
                       completed: true,
                       annotations: annotation_values,
                       links: {
                               project: project_id,
                               workflow: workflow_id,
                               set_member_subject: set_member_subject.id,
                              }
                      }
    }
  post :create, params
end

def create_classification
  setup_create_request(project.id, workflow.id, set_member_subject)
end

shared_context "a classification create" do
  it "should return 201" do
    create_classification
    expect(response.status).to eq(201)
  end

  it "should set the Location header as per JSON-API specs" do
    create_classification
    id = created_classification_id
    expect(response.headers["Location"]).to eq("http://test.host/api/classifications/#{id}")
  end

  it "should create the classification" do
    expect do
      create_classification
    end.to change{Classification.count}.from(0).to(1)
  end
end

describe Api::V1::ClassificationsController, type: :controller do
  let!(:user) { create(:user) }
  let(:classification) { create(:classification, user: user) }
  let(:project) { create(:full_project) }
  let!(:workflow) { project.workflows.first }
  let!(:set_member_subject) { workflow.subject_sets.first.set_member_subjects.first }
  let(:created_classification_id) { created_instance_id("classifications") }

  let(:api_resource_name) { "classifications" }
  let(:api_resource_attributes) do
    [ "id", "annotations", "created_at" ]
  end
  let(:api_resource_links) do
    [ "classifications.project",
     "classifications.set_member_subject",
     "classifications.user",
     "classifications.user_group" ]
  end

  let(:scopes) { %w(classification) }
  let(:authorized_user) { user }
      let(:resource_class) { Classification }

  context "logged in user" do
    before(:each) do
      default_request user_id: user.id, scopes: scopes
    end

    describe "#index" do
      let!(:classifications) { create_list(:classification, 2, user: user) }
      let!(:private_resource) { create(:classification) }
      let(:n_visible) { 2 }
      
      it_behaves_like "is indexable"
    end

    describe "#show" do
      let(:resource) { classification }
      it_behaves_like "is showable"
    end

    describe "#create" do
      it "should create the user project preferences" do
        create_classification
        expect(UserProjectPreference.where(user: user, project: project).first).to_not be_nil
      end

      it "should set the communication preferences to the user's default" do
        create_classification
        expect(UserProjectPreference.where(user: user, project: project).first.email_communication).to eq(user.project_email_communication)
      end

      it 'should not create the user project preferences if they already exist' do
        create(:user_project_preference, user: user, project: project)
        create_classification
        expect(UserProjectPreference.where(user: user, project: project).length).to eq(1)
      end

      it "should setup the add seen command to cellect" do
        expect(stubbed_cellect_connection).to receive(:add_seen)
          .with(
                subject_id: set_member_subject.id,
                workflow_id: workflow.id,
                user_id: user.id,
                host: 'example.com'
               )
        create_classification
      end

      it "should set the user" do
        create_classification
        id = created_instance_id("classifications")
        expect(Classification.find(created_classification_id)
               .user.id).to eq(user.id)
      end

      it_behaves_like "a classification create"

      describe "track user seen subjects" do
        let(:expected_params) do
          {set_member_subject_id: set_member_subject.id,
           workflow: workflow,
           user: user }
        end

        it "should add the seen subject for the user" do
          expect(UserSeenSubject).to receive(:add_seen_subject_for_user)
            .with(**expected_params)
          create_classification
        end

        it "should create a user seen subject" do
          expect do
            create_classification
          end.to change{UserSeenSubject.count}.from(0).to(1)
        end
      end
    end
  end

  describe "#update" do
    context "an incomplete classification" do
      let(:resource) { create(:classification, user: authorized_user, completed: false) }
      let(:test_attr) { :completed }
      let(:test_attr_value) { true }
      let(:update_params) do
        {
         classifications: {
                           completed: true,
                           annotations: [{ key: "q-1", value: "round" }]
                          }
        }
      end

      it_behaves_like "is updatable"
      
    end

    context "a complete classification" do
      it 'should return 403' do
        default_request scopes: scopes, user_id: authorized_user.id
        classification = create(:classification, user: authorized_user, completed: true)
        put :update, id: classification.id
        expect(response.status).to eq(403)
      end
    end
  end
  
  describe "#destroy" do
    context "an incomplete classification" do
      let(:resource) { create(:classification, user: authorized_user, completed: false) }
      it_behaves_like "is destructable"
    end

    context "a complete classification" do
      it 'should return 403' do
        default_request scopes: scopes, user_id: authorized_user.id
        classification = create(:classification, user: authorized_user, completed: true)
        delete :destroy, id: classification.id
        expect(response.status).to eq(403)
      end
    end
  end

  context "a non-logged in user" do
    before(:each) do
      stub_content_filter
    end

    describe "#create" do

      it "should not set the user" do
        create_classification
        expect(Classification.find(created_classification_id).user).to be_blank
      end

      it_behaves_like "a classification create"
    end
  end
end
