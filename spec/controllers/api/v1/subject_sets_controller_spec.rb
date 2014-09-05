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

  before(:each) do
    default_request scopes: scopes, user_id: owner.id
  end

  describe '#index' do
    before(:each){ get :index }

    it 'should return 200' do
      expect(response.status).to eq 200
    end

    it 'should have 2 items by default' do
      expect(json_response[api_resource_name].length).to eq 2
    end

    it_behaves_like 'an api response'
  end

  describe '#show' do
    before(:each) do
      get :show, id: subject_set.id
    end

    it 'should return 200' do
      expect(response.status).to eq 200
    end

    it 'should return the requested subject_set' do
      expect(json_response[api_resource_name].length).to eq 1
    end

    it_behaves_like 'an api response'
  end

  describe '#update' do
    it 'should be implemented'
  end

  describe '#create' do
    let(:authorized_user) { owner }
    let(:test_attr) { :name}
    let(:test_attr_value) { 'Test subject set' }
    let(:create_params) do
      {
       subject_sets: {
                      name: 'Test subject set',
                      project_id: project.id
                     }
      }
    end
    it_behaves_like "is creatable"
  end

  describe '#destroy' do
    let(:authorized_user) { owner }
    let(:resource) { subject_set }

    it_behaves_like "is destructable"
  end
end
