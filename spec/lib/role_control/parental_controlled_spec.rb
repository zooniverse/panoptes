
require 'spec_helper'

describe RoleControl::ParentalControlled do
  setup_role_control_tables
  let(:user) { create(:user) }
  let(:enrolled_actor) { ApiUser.new(user) }
  let(:parent) { ControlledTable.create! }
  let(:controlled) { TestParentControlTable.create! }

  describe "::scope_for" do
    let(:klass) { controlled.class }

    before do
      controlled
      create_roles_join_instance(%w(test_role), parent, user)
    end

    after do
      klass.scope_for(:update, enrolled_actor)
    end

    it "should call join on the parent" do
      expect(klass)
        .to receive(:joins)
        .with(parent.class.model_name.singular.to_sym)
        .and_call_original
    end

    it "should call scope_for on the parent" do
      expect(parent.class).to receive(:scope_for).with(:update, enrolled_actor, {})
    end
  end
end
