
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
    context "without test no join parent scope feature flag" do
      it "should call join on the parent" do
        expect(klass)
          .to receive(:joins)
          .with(parent.class.model_name.singular.to_sym)
          .and_call_original
      end
    end

    context "with test no join scope feature flag" do
      let(:parent_fk) do
        klass.reflect_on_association(parent.model_name.singular).foreign_key
      end

      it "should call filter on belongs_to parent fk" do
        Panoptes.flipper[:test_no_join_parental_scope].enable
        expect(klass)
          .to receive(:where)
          .with(parent_fk => sub_select_scope.select(:id))
          .and_call_original
      end
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
      expect(parent.class).to receive(:scope_for).with(:update, enrolled_actor, {})
    end
  end
end
