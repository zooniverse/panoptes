require 'spec_helper'

describe RoleControl::RoledController, type: :controller do
  setup_role_control_tables

  let!(:enrolled) { EnrolledTable.create! }
  
  let!(:controlled) do
    ControlledTable.create! do |c|
      c.visible_to = ["admin"]
    end
  end

  controller(ApplicationController) do
    include RoleControl::RoledController
    access_control_for :index, resource_class: ControlledTable

    def api_user
      EnrolledTable.first
    end

    def index
      render json: { test: "YAY!" }
    end
  end

  describe "user is enrolled on controlled object" do
    before(:each) do
      create_role_model_instance(["admin"], controlled, enrolled)
    end

    it 'should return 200' do
      get :index, id: controlled.id
      expect(response.status).to eq(200)
    end
  end

  describe "user is not enrolled on controlled object" do
    it 'should raise a ControlControl::AccessDenied error' do
      expect{ get :index, id: controlled.id }.to raise_error(ControlControl::AccessDenied)
    end
  end
end
