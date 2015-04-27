require 'spec_helper'

describe Api::V1::SubjectSetsController, type: :controller do
  let!(:subject_sets) { create_list :subject_set_with_subjects, 2 }
  let(:subject_set) { subject_sets.first }
  let(:project) { subject_set.project }
  let(:owner) { project.owner }
  let(:api_resource_name) { 'subject_sets' }

  let(:api_resource_attributes) { %w(id display_name retired_set_member_subjects_count set_member_subjects_count created_at updated_at retirement metadata) }
  let(:api_resource_links) { %w(subject_sets.project subject_sets.workflows) }

  let(:scopes) { %w(public project) }
  let(:resource_class) { SubjectSet }
  let(:authorized_user) { owner }

  before(:each) do
    default_request scopes: scopes, user_id: owner.id
  end

  describe '#index' do
    let(:private_project) { create(:project, private: true) }
    let!(:private_resource) { create(:subject_set, project: private_project)  }
    let(:n_visible) { 2 }

    it_behaves_like 'is indexable'
  end

  describe '#show' do
    let(:resource) { subject_set }

    it_behaves_like 'is showable'
  end

  describe '#update' do
    let(:subjects) { create_list(:subject, 4) }
    let(:workflow) { create(:workflow, project: project) }
    let(:resource) { create(:subject_set, project: project) }
    let(:test_attr) { :display_name }
    let(:test_attr_value) { "A Better Name" }
    let(:test_relation) { :subjects }
    let(:test_relation_ids) { subjects.map(&:id) }
    let(:update_params) do
      {
        subject_sets: {
          display_name: "A Better Name",
          retirement: {
            criteria: "classification_count"
          },
          links: {
            workflows: [workflow.id.to_s],
            subjects: subjects.map(&:id).map(&:to_s)
          }

        }
      }
    end

    it_behaves_like "is updatable"

    it_behaves_like "has updatable links"
  end

  describe '#create' do
    let(:test_attr) { :display_name}
    let(:test_attr_value) { 'Test subject set' }
    let(:create_params) do
      {
        subject_sets: {
          display_name: 'Test subject set',
          retirement: {
            criteria: "classification_count"
          },
          metadata: {
            location: "Africa"
          },
          links: {
            project: project.id
          }
        }
      }
    end

    context "create a new subject set" do
      it_behaves_like "is creatable"
    end

    context "create a subject set from a collection" do

      before(:each) do
        ps = create_params
        ps[:subject_sets][:links][:collection] = collection.id.to_s
        default_request user_id: authorized_user.id, scopes: scopes
        post :create, ps
      end

      context "when a user can access the collection" do
        let(:collection) { create(:collection_with_subjects) }
        it "should create a new subject set with the collection's subjects" do
          set = SubjectSet.find(created_instance_id(api_resource_name))
          expect(set.subjects).to match(collection.subjects)
        end
      end

      context "when the user cannot access the collection" do
        let(:collection) { create(:collection_with_subjects, private: true) }
        it "should return 404" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe '#destroy' do
    let(:resource) { subject_set }

    it_behaves_like "is destructable"
  end
end
