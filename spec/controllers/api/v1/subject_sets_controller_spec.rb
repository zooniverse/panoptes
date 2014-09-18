require 'spec_helper'

describe Api::V1::SubjectSetsController, type: :controller do
  let!(:subject_sets) { create_list :subject_set_with_subjects, 2 }
  let(:subject_set) { subject_sets.first }
  let(:project) { subject_set.project }
  let(:owner) { project.owner }
  let(:api_resource_name) { 'subject_sets' }

  let(:api_resource_attributes) { %w(id name set_member_subjects_count created_at updated_at) }
  let(:api_resource_links) { %w(subject_sets.project subject_sets.workflows) }
  
  let(:scopes) { %w(public project) }
  let(:resource_class) { SubjectSet }
  let(:authorized_user) { owner }

  before(:each) do
    default_request scopes: scopes, user_id: owner.id
  end

  describe '#index' do
    let(:private_project) { create(:project, visible_to: ["collaborator"]) }
    let!(:private_resource) { create(:subject_set, project: private_project)  }
    let(:n_visible) { 2 }
    
    it_behaves_like 'is indexable'
  end

  describe '#show' do
    let(:resource) { subject_set }
    
    it_behaves_like 'is showable'
  end

  describe '#update' do
    it 'should be implemented'
  end

  describe '#create' do
    let(:test_attr) { :name}
    let(:test_attr_value) { 'Test subject set' }
    let(:create_params) do
      {
       subject_sets: {
                      name: 'Test subject set',
                      links: {
                              project: project.id
                             }
                     }
      }
    end
    it_behaves_like "is creatable"
  end

  describe '#destroy' do
    let(:resource) { subject_set }

    it_behaves_like "is destructable"
  end
end
