require 'spec_helper'

describe Api::V1::SubjectQueuesController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:api_resource_name) { 'subject_queues' }
  let(:api_resource_attributes) { %w(id) }
  let(:api_resource_links) { %w(subject_queues.user subject_queues.workflow subject_queues.set_member_subjects) }

  let(:project) { create(:project, owner: authorized_user) }
  let(:workflow) { create(:workflow_with_subject_set, project: project) }
  let(:resource) { create(:subject_queue, workflow: workflow, subject_set: nil) }
  let!(:set_member_subjects) do
    create_list(:set_member_subject, 3, subject_set: workflow.subject_sets.first)
  end
  let(:set_member_subject_ids) { set_member_subjects.map(&:id) }
  let(:subjects) { set_member_subjects.map(&:subject) }
  let(:subject_ids) { subjects.map(&:id) }

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
    let(:test_attr_value) { set_member_subject_ids }
    let(:update_params) do
      { subject_queues:
          {
            links: {
              subjects: subject_ids
            }
          }
      }
    end

    it_behaves_like "is updatable"

    it_behaves_like "has updatable links" do
      let(:stringified_test_relation_ids) { set_member_subject_ids.map(&:to_s) }
      let(:test_relation_ids) { subject_ids }
      let(:test_relation) { :set_member_subjects }
    end
  end

  describe "#update_links" do
    let(:rev_subject_ids) { subject_ids.reverse }
    let(:test_attr_value) { rev_subject_ids }
    let(:test_relation_ids) { rev_subject_ids * 2 }
    let(:test_relation) { :subjects }
    let(:resource_id) { :subject_queue_id }
    let(:q_sms_ids) do
      Array.wrap(create(:set_member_subject, subject_set: workflow.subject_sets.first).id)
    end
    let!(:resource) do
      create(:subject_queue, workflow: workflow, subject_set: nil, set_member_subject_ids: q_sms_ids)
    end
    let(:sms_ids) { set_member_subjects.map(&:id) }
    let(:expected_ids) { sms_ids.reverse | q_sms_ids }

    it_behaves_like "supports update_links" do
      let!(:old_ids) { resource.set_member_subject_ids }
      let(:linked_resources) { updated_resource.set_member_subjects }
      let(:stringified_test_relation_ids) { sms_ids.map(&:to_s) }

      it "prepend the ids and remove dups" do
        expect(updated_resource.set_member_subject_ids).to eq(expected_ids)
      end
    end
  end

  describe "#create" do
    let(:test_attr) { :set_member_subject_ids }
    let(:test_attr_value) { set_member_subject_ids }
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
