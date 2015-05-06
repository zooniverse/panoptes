require 'spec_helper'

RSpec.describe Api::V1::SetMemberSubjectsController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:subject_set) { create(:subject_set, project: create(:project, owner: authorized_user)) }
  let!(:set_member_subjects) { create_list(:set_member_subject, 2, subject_set: subject_set) }
  let(:api_resource_name) { 'set_member_subjects' }
  let(:api_resource_attributes) { %w(id priority) }
  let(:api_resource_links) { %w(set_member_subjects.subject set_member_subjects.subject_set set_member_subjects.retired_workflows) }

  let(:scopes) { %w(public project) }
  let(:resource) { set_member_subjects.first }
  let(:resource_class) { SetMemberSubject }

  describe "#index" do
    let!(:private_resource) do
      ss = create(:subject_set, project: create(:project, private: true))
      create(:set_member_subject, subject_set: ss)
    end

    let(:n_visible) { 2 }

    it_behaves_like "is indexable"

    describe "top level links" do

      it "should not include a nil key for the belongs_to_many association" do
        default_request scopes: scopes, user_id: authorized_user.id if authorized_user
        get :index
        expect(json_response["links"][""]).to be_nil
      end
    end
  end

  describe "#show" do
    it_behaves_like "is showable"
  end

  describe "#update" do
    let(:test_attr) { :retired_workflows }
    let(:workflow) { resource.subject_set.workflows.first }
    let(:test_attr_value) { [workflow] }
    let(:update_params) do
      { set_member_subjects: { links: {retired_workflows: [workflow.id] } } }
    end

    it_behaves_like "is updatable"
  end

  describe "#create" do
    let(:test_attr) { :subject_set }
    let(:test_attr_value) { subject_set }
    let(:create_params) do
      {
        set_member_subjects: {
          links: {
            subject: create(:subject).id.to_s,
            subject_set: subject_set.id.to_s
          }
        }
      }
    end

    it_behaves_like "is creatable"

    context "set the random value" do
      before(:each) do
        default_request user_id: authorized_user.id, scopes: scopes
        post :create, create_params
      end

      it 'should set the random value for a subject' do
        sms = SetMemberSubject.find(created_instance_id(api_resource_name))
        expect(sms.random).to_not be_nil
      end
    end
  end

  describe "#destroy" do
    it_behaves_like "is destructable"
  end
end
