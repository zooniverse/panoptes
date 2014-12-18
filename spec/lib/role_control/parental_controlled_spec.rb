
require 'spec_helper'

class TestParentControl
  include RoleControl::ParentalControlled

  can_through_parent :parent, :read

  attr_reader :parent

  def initialize(parent)
    @parent = parent
  end
end

describe RoleControl::ParentalControlled do
  setup_role_control_tables

  let(:enrolled_actor) { EnrolledActorTable.create! }
  let(:controlled) { ControlledTable.create! }
  let!(:relation) { create_roles_join_instance(%w(test_parent_role test_role), controlled, enrolled_actor)  }

  let(:tpc) { TestParentControl.new(controlled) }

  describe "::scope_for" do
  end
end
