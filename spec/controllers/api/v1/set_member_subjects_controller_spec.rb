require 'spec_helper'

RSpec.describe Api::V1::SetMemberSubjectsController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:subject_set) { create(:subject_set, project: create(:project, owner: authorized_user)) }
  let!(:set_member_subjects) { create_list(:set_member_subject, 2, subject_set: subject_set) }
  let(:api_resource_name) { 'set_member_subjects' }
  let(:api_resource_attributes) { %w(id priority) }
  let(:api_resource_links) { %w(set_member_subjects.subject set_member_subjects.subject_set) }

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
    let(:linked_subject) { create(:subject) }
    let(:test_attr) { :subject_set }
    let(:test_attr_value) { subject_set }
    let(:create_params) do
      {
        set_member_subjects: {
          links: {
            subject: linked_subject.id.to_s,
            subject_set: subject_set.id.to_s
          }
        }
      }
    end

    it_behaves_like "is creatable"

    it 'should call the set count worker after action' do
      default_request user_id: authorized_user.id, scopes: scopes
      expect(SubjectSetSubjectCounterWorker).to receive(:perform_async).once
      post :create, params: create_params
    end

    it 'should call the sws status create worker' do
      linked_workflow_ids = subject_set.subject_sets_workflows.pluck(:workflow_id)
      linked_workflow_ids.each do |workflow_id|
        expect(SubjectWorkflowStatusCreateWorker)
        .to receive(:perform_in)
        .with(kind_of(Numeric), linked_subject.id, workflow_id)
      end
      default_request user_id: authorized_user.id, scopes: scopes
      post :create, params: create_params
    end
  end

  describe "#destroy" do
    it_behaves_like "is destructable"

    describe "lifecycle callbacks" do
      before do
        default_request user_id: authorized_user.id, scopes: scopes
      end

      it 'should call the set count worker' do
        expect(SubjectSetSubjectCounterWorker)
          .to receive(:perform_async)
          .with(resource.subject_set_id)
        delete :destroy, params: { id: resource.id }
      end

      it 'should call the subject removal worker' do
        expect(SubjectRemovalWorker)
          .to receive(:perform_async)
          .with(resource.subject_id)
        delete :destroy, params: { id: resource.id }
      end
    end
  end
end
