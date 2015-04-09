require 'spec_helper'

describe Api::V1::SubjectQueuesController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:api_resource_name) { 'subject_queues' }
  let(:api_resource_attributes) { %w(id) }
  let(:api_resource_links) { %w(subject_queues.user subject_queues.workflow subject_queues.subjects) }

  let(:project) { create(:project, owner: authorized_user) }
  let(:workflow) { create(:workflow_with_subject_set, project: project) }
  let(:resource) { create(:subject_queue, workflow: workflow, subject_set: nil) }
  let!(:subjects) { create(:subject); create_list(:set_member_subject, 3, subject_set: workflow.subject_sets.first) }
  let(:subject_ids) { subjects.map(&:subject_id).map(&:to_s) }

  let(:scopes) { %w(public project) }
  let(:resource_class) { SubjectQueue }

  describe "#index" do
    let!(:resources) { create_list(:subject_queue, 2, workflow: workflow) }
    let!(:private_resource) { create(:subject_queue) }
    let(:n_visible) { 2 }

    it_behaves_like "is indexable"
  end

  describe "#show" do
    let!(:resources) { create_list(:subject_queue, 2, user: authorized_user) }

    it_behaves_like "is showable"
  end

  describe "#update" do
    let(:test_attr) { :set_member_subject_ids }
    let(:test_attr_value) { subjects.map(&:id) }
    let(:update_params) do
      {
        subject_queues: {
                             links: {
                                     subjects: subject_ids
                                    }
                            }
      }
    end
    
    it_behaves_like "is updatable"
  end

  describe "#create" do
    let(:test_attr) { :set_member_subject_ids }
    let(:test_attr_value) { subjects.map(&:id) }
    let(:create_params) do
      {
       subject_queues: {
                             links: {
                                     workflow: workflow,
                                     user: create(:user),
                                     subjects: subject_ids
                                    }
                            }
      }
    end
      
    it_behaves_like "is creatable"
  end

  describe "#destroy" do
    it_behaves_like "is destructable"
  end
end
