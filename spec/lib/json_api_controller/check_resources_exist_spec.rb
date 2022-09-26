require 'spec_helper'

describe JsonApiController::CheckResourcesExist, type: :controller do
  setup_role_control_tables

  let!(:enrolled_actor) { create(:user) }

  let!(:controlled) do
    ControlledTable.create! do |c|
      c.private = true
    end
  end

  controller(ApplicationController) do
    include JsonApiController::CheckResourcesExist
    include JsonApiController::PunditPolicy

    def api_user
      ApiUser.new(User.first)
    end

    def resource_class
      ControlledTable
    end

    def resource_name
      "controlled_table"
    end

    def resource_ids
      JsonApiController::ResourceIds.from(params, resource_name)
    end

    def update
      render nothing: true
    end

    def show
      render nothing: true
    end

    def index
      render nothing: true
    end
  end

  describe "user is enrolled on controlled object" do
    before(:each) do
      create_roles_join_instance(["admin", "test_role"], controlled, enrolled_actor)
    end

    context "route with access control using it's own name" do
      it 'should return 200' do
        put :update, params: { id: controlled.id }
        expect(response.status).to eq(200)
      end
    end

    context "route with access control using a different method" do
      it 'should return 200' do
        get :show, params: { id: controlled.id }
        expect(response.status).to eq(200)
      end
    end
  end

  describe "user is not enrolled on controlled object" do
    it 'should raise an AccessDenied error' do
      expect{ put :update, params: { id: controlled.id } }.to raise_error(JsonApiController::AccessDenied)
    end
  end

  describe "id params are extracted correctly" do
    before do
      routes.draw do
        get "index" => "anonymous#index"
      end
    end

    it 'should handle missing id values' do
      # manually skip the pundit policy run validation
      # as this spec won't return resource ids so won't activate the scope
      # lookup in JsonApiController::CheckResourcesExist.resources_exist?
      allow(controller).to receive(:policy_scoped?).and_return(true)
      expect{
        get :index, params: { id: nil }
      }.not_to raise_error
    end
  end
end
