
require 'spec_helper'

describe RoleControl::ParentalControlled do
  setup_role_control_tables

  let(:enrolled_actor) { EnrolledActorTable.create! }
  let(:controlled) { ControlledTable.create! }
  let!(:relation) { create_roles_join_instance(%w(test_parent_role test_role), controlled, enrolled_actor)  }

  describe "::scope_for" do
  end
end
