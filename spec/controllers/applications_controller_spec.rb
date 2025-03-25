require 'spec_helper'

describe ApplicationsController, type: :controller do
  let(:normal_user) { create(:user) }
  let(:admin_user)  { create(:user, admin: true) }

  describe '#index' do
    context 'when logged in as a normal user' do
      before do
        create(:application, owner: normal_user)
        create(:application)
        allow(normal_user).to receive(:oauth_applications)
        allow(controller).to receive(:current_user).and_return(normal_user)
      end

      it 'shows only the logged in users applications', :aggregate_failures do
        sign_in normal_user
        get :index
        expect(response).to be_ok
        expect(normal_user).to have_received(:oauth_applications)
      end
    end

    context 'when logged in as an admin user' do
      before do
        create(:application)
        create(:application)
        allow(Doorkeeper::Application).to receive(:all).and_call_original
      end

      it 'returns all applications for admins', :aggregate_failures do
        sign_in admin_user
        get :index
        expect(response).to be_ok
        expect(Doorkeeper::Application).to have_received(:all).once
      end
    end
  end

  describe '#show' do
    let(:application) { create(:application) }

    it 'shows your own application' do
      sign_in application.owner
      get :show, params: { id: application.id }
      expect(response).to be_ok
    end

    it 'does not show other applications' do
      sign_in normal_user
      get :show, params: { id: application.id }
      expect(response.status).to eq(404)
    end

    it 'lets admins see all applications' do
      sign_in admin_user
      get :show, params: { id: application.id }
      expect(response).to be_ok
    end
  end

  describe '#create' do
    before do
      sign_in normal_user
    end

    it 'should set the owner of the application' do
      post :create, params: {
        application: { name: 'test app', redirect_uri: 'https://example.com' }
      }
      expect(Doorkeeper::Application.first.owner).to eq(normal_user)
    end

    it 'should allows insecure localhost scheme URIs' do
      expect {
        post :create, params: {
          application: { name: 'test app', redirect_uri: 'http://localhost' }
        }
      }.to change {
        Doorkeeper::Application.count
      }.by(1)
    end

    it 'should allows insecure local zooniverse scheme URIs' do
      expect {
        post :create, params: {
          application: { name: 'test app', redirect_uri: 'http://local.zooniverse.org' }
        }
      }.to change {
        Doorkeeper::Application.count
      }.by(1)
    end

    it 'should not allow insecure non-localhost scheme URIs' do
      sign_in normal_user
      expect {
        post :create, params: {
          application: { name: 'test app', redirect_uri: 'http://example.com' }
        }
      }.not_to change {
        Doorkeeper::Application.count
      }
    end
  end

  describe '#update' do
    let(:application) { create(:application, name: 'test app') }

    it 'updates your own application' do
      sign_in application.owner
      put :update, params: { id: application.id, application: { name: 'changed' } }
      expect(application.reload.name).to eq('changed')
    end

    it 'does not update other applications' do
      sign_in normal_user
      put :update, params: { id: application.id, application: { name: 'changed' } }
      expect(response.status).to eq(404)
      expect(application.reload.name).to eq('test app')
    end

    it 'lets admins update all applications' do
      sign_in admin_user
      put :update, params: { id: application.id, application: { name: 'changed' } }
      expect(application.reload.name).to eq('changed')
    end

    it 'allows insecure localhost scheme URIs' do
      sign_in application.owner
      redirect_uri = 'http://localhost'
      expect {
        put :update, params: { id: application.id, application: {
          redirect_uri: redirect_uri
        } }
      }.to change {
        application.reload.redirect_uri
      }.to(redirect_uri)
    end

    it 'allows insecure localhost scheme URIs' do
      sign_in application.owner
      redirect_uri = 'http://local.zooniverse.org'
      expect {
        put :update, params: { id: application.id, application: {
          redirect_uri: redirect_uri
        } }
      }.to change {
        application.reload.redirect_uri
      }.to(redirect_uri)
    end

    it 'should not allow insecure non-localhost scheme URIs' do
      sign_in application.owner
      original_redirect = application.redirect_uri
      put :update, params: { id: application.id, application: { redirect_uri: 'http://example.com' } }
      expect(application.redirect_uri).to eq(original_redirect)
    end
  end

  describe '#destroy' do
    let(:application) { create(:application) }

    it 'destroys your own application' do
      sign_in application.owner
      delete :destroy, params: { id: application.id }
      expect(Doorkeeper::Application.count).to eq(0)
    end

    it 'does not destroy other applications' do
      sign_in normal_user
      delete :destroy, params: { id: application.id }
      expect(response.status).to eq(404)
      expect(Doorkeeper::Application.count).to eq(1)
    end

    it 'lets admins destroy all applications' do
      sign_in admin_user
      delete :destroy, params: { id: application.id }
      expect(Doorkeeper::Application.count).to eq(0)
    end
  end
end
