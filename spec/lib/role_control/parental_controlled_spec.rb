
require 'spec_helper'

describe RoleControl::ParentalControlled do
  setup_role_control_tables
  let(:user) { create(:user) }
  let(:enrolled_actor) { ApiUser.new(user) }
  let(:parent) { ControlledTable.create! }
  let(:controlled) { TestParentControlTable.create! }
  let(:klass) { controlled.class }

  before do
    controlled
    create_roles_join_instance(%w(test_role), parent, user)
  end

  shared_examples_for "a parental controlled" do
    it "should call filter on belongs_to parent fk" do
      parent_scope_for = parent.class.scope_for(:update, enrolled_actor, {})
      expect(klass)
        .to receive(:where)
        .with(klass.parent_foreign_key => parent_scope_for.pluck(:id))
        .and_call_original
    end
  end

  describe "::public_scope" do
    let(:parent) { ControlledTable.create!(private: false) }

    it_behaves_like "a parental controlled" do
      let(:sub_select_scope) { parent.class.public_scope }
      after do
        klass.public_scope
      end
    end
  end

  describe "::private_scope" do
    it_behaves_like "a parental controlled" do
      let(:sub_select_scope) { parent.class.private_scope }
      after do
        klass.private_scope
      end
    end
  end

  describe "::scope_for" do
    let(:sub_select_scope) { parent.class.scope_for(:update, enrolled_actor, {}) }
    after do
      klass.scope_for(:update, enrolled_actor, {})
    end

    it_behaves_like "a parental controlled"

    it "should call scope_for on the parent" do
      expect(parent.class)
        .to receive(:scope_for)
        .with(:update, enrolled_actor, {})
        .and_call_original
    end
  end
end
