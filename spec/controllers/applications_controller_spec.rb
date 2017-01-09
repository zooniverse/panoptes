require "spec_helper"

describe ApplicationsController, type: :controller do
  describe '#index' do
    it 'shows your own application' do
      user = create(:user)
      application1 = create(:application, owner: user)
      application2 = create(:application)

      sign_in user
      get :index
      expect(response).to be_ok
      expect(assigns[:applications]).to eq([application1])
    end

    it 'lets admins see all applications' do
      user = create(:user, admin: true)
      application1 = create(:application, owner: user)
      application2 = create(:application)

      sign_in user
      get :index
      expect(response).to be_ok
      expect(assigns[:applications]).to eq([application1, application2])
    end
  end

  describe '#show' do
    let(:application) { create(:application) }

    it 'shows your own application' do
      sign_in application.owner
      get :show, id: application.id
      expect(response).to be_ok
    end

    it 'does not show other applications' do
      user = create(:user)
      sign_in user
      get :show, id: application.id
      expect(response.status).to eq(404)
    end

    it 'lets admins see all applications' do
      user = create(:user, admin: true)
      sign_in user
      get :show, id: application.id
      expect(response).to be_ok
    end
  end

  describe "#create" do
    it 'should set the owner of the application' do
      user = create(:user, admin: true)
      sign_in user
      post :create, application: { name: "test app", redirect_uri: "https://test.example.com" }
      expect(Doorkeeper::Application.first.owner).to eq(user)
    end
  end

  describe '#update' do
    let(:application) { create(:application, name: 'test app') }

    it 'shows your own application' do
      sign_in application.owner
      put :update, id: application.id, application: {name: 'changed'}
      expect(application.reload.name).to eq('changed')
    end

    it 'does not show other applications' do
      user = create(:user)
      sign_in user
      put :update, id: application.id, application: {name: 'changed'}
      expect(response.status).to eq(404)
      expect(application.reload.name).to eq('test app')
    end

    it 'lets admins see all applications' do
      user = create(:user, admin: true)
      sign_in user
      put :update, id: application.id, application: {name: 'changed'}
      expect(application.reload.name).to eq('changed')
    end
  end

  describe '#destroy' do
    let(:application) { create(:application) }

    it 'destroys your own application' do
      sign_in application.owner
      delete :destroy, id: application.id
      expect(Doorkeeper::Application.count).to eq(0)
    end

    it 'does not destroy other applications' do
      user = create(:user)
      sign_in user
      delete :destroy, id: application.id
      expect(response.status).to eq(404)
      expect(Doorkeeper::Application.count).to eq(1)
    end

    it 'lets admins destroy all applications' do
      user = create(:user, admin: true)
      sign_in user
      delete :destroy, id: application.id
      expect(Doorkeeper::Application.count).to eq(0)
    end
  end
end
