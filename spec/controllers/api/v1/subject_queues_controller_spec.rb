require 'spec_helper'

describe Api::V1::SubjectQueuesController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:api_resource_name) { 'subject_queues' }
  let(:api_resource_attributes) { %w(id) }
  let(:api_resource_links) { %w(subject_queues.user subject_queues.workflow subject_queues.subjects) }

  let(:project) { create(:project, owner: authorized_user) }
  let(:workflow) { create(:workflow, project: project) }
  let(:resource) { create(:user_subject_queue, workflow: workflow) }
  let(:subjects) { create_list(:subject, 3) }
  let(:subject_ids) { subjects.map(&:id).map(&:to_s) }

  let(:scopes) { %w(public project) }
  let(:resource_class) { UserSubjectQueue }

  describe "#index" do
    let!(:resources) { create_list(:user_subject_queue, 2, workflow: workflow) }
    let!(:private_resource) { create(:user_subject_queue) }
    let(:n_visible) { 2 }

    it_behaves_like "is indexable"
  end

  describe "#show" do
    let!(:resources) { create_list(:user_subject_queue, 2, user: authorized_user) }

    it_behaves_like "is showable"
  end

  describe "#update" do
    let(:test_attr) { :subject_ids }
    let(:test_attr_value) { subject_ids.map(&:to_i) }
    let(:update_params) do
      {
       user_subject_queues: {
                             links: {
                                     subjects: subject_ids
                                    }
                            }
      }
    end
    
    it_behaves_like "is updatable"
  end

  describe "#create" do
    let(:test_attr) { :subject_ids }
    let(:test_attr_value) { subject_ids.map(&:to_i) }
    let(:create_params) do
      {
       user_subject_queues: {
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
