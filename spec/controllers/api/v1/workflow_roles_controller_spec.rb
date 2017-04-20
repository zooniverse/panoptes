require 'spec_helper'

RSpec.describe Api::V1::WorkflowRolesController, type: :controller do
  let(:authorized_user){ create :user }
  let(:workflow_user){ create :user }
  let(:project){ create :project, owner: authorized_user }
  let(:workflow){ create :workflow, project: project }

  let!(:acl) do
    create :access_control_list, resource: workflow, roles: ['collaborator'], user_group: workflow_user.identity_group
    create :access_control_list, resource: workflow, roles: ['collaborator'], user_group: create(:user).identity_group
  end

  let(:api_resource_name){ 'workflow_roles' }
  let(:api_resource_attributes){ %w(id roles) }
  let(:api_resource_links){ %w(workflow_roles.workflow) }

  let(:scopes){ %w(public project) }
  let(:resource){ acl }
  let(:resource_class){ AccessControlList }

  describe '#index' do
    let(:private_project){ create :project, private: true }
    let!(:private_resource){ create :access_control_list, resource: create(:workflow, project: private_project) }
    let(:n_visible){ 2 }

    it_behaves_like 'is indexable'

    describe 'custom owner links' do
      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id if authorized_user
        get :index
      end

      it_behaves_like 'it has custom owner links'
    end

    context 'filter by user_id' do
      before(:each) do
        get :index, user_id: workflow_user.id
      end

      it 'should only return roles belonging to the user' do
        owner_links = json_response[api_resource_name][0]['links']['owner']
        expect(owner_links).to include('type' => 'users', 'id' => workflow_user.id.to_s)
      end

      it 'should only return one role' do
        expect(json_response[api_resource_name].length).to eq 1
      end
    end
  end

  describe '#show' do
    it_behaves_like 'is showable'
  end

  describe '#update' do
    let(:unauthorized_user){ create :user }
    let(:test_attr){ :roles }
    let(:test_attr_value){ %w(collaborator) }

    let(:update_params) do
      { workflow_roles: { roles: ['collaborator'] } }
    end

    it_behaves_like 'is updatable'
  end

  describe '#create' do
    let(:test_attr){ :roles }
    let(:test_attr_value){ ['collaborator'] }

    let(:create_params) do
      {
        workflow_roles: {
          roles: ['collaborator'],
          links: {
            user: create(:user).id.to_s,
            workflow: workflow.id.to_s
          }
        }
      }
    end

    it_behaves_like 'is creatable'

    context 'a user which cannot edit the workflow' do
      let(:user){ create(:user) }

      it 'should return an error code' do
        default_request scopes: scopes, user_id: user.id
        post :create, create_params
        expect(response).to have_http_status :unprocessable_entity
      end
    end
  end

  describe '#destroy' do
    it_behaves_like 'is destructable'
  end
end
