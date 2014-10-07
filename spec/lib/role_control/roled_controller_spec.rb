require 'spec_helper'

describe RoleControl::RoledController, type: :controller do
  setup_role_control_tables

  let!(:enrolled_actor) { EnrolledActorTable.create! }
  
  let!(:controlled) do
    ControlledTable.create! do |c|
      c.visible_to = ["admin"]
    end
  end

  controller(ApplicationController) do
    include RoleControl::RoledController
    access_control_for :index, [:show, :index]

    def api_user
      EnrolledActorTable.first
    end

    def resource_class
      ControlledTable
    end

    def resource_sym
      :controlled_tables
    end

    def index
      render json: { test: "YAY!" }
    end

    def show
      render json: { test: "YAY!" }
    end
  end

  describe "user is enrolled on controlled object" do
    before(:each) do
      create_roles_join_instance(["admin"], controlled, enrolled_actor)
    end

    context "route with access control using it's own name" do
      it 'should return 200' do
        get :index, id: controlled.id
        expect(response.status).to eq(200)
      end
    end

    context "route with access control using a different method" do
      it 'should return 200' do
        get :show, id: controlled.id
        expect(response.status).to eq(200)
      end
    end
  end

  describe "user is not enrolled on controlled object" do
    it 'should raise a ControlControl::AccessDenied error' do
      expect{ get :index, id: controlled.id }.to raise_error(ControlControl::AccessDenied)
    end
  end
end
