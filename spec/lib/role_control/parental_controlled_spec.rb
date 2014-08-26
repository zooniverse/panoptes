
require 'spec_helper'

class TestParentControl
  include RoleControl::ParentalControlled

  can_by_role_through_parent :read, :parent
  can_by_role_through_parent :edit, :parent, :test_parent_role

  attr_reader :parent

  def initialize(parent)
    @parent = parent
  end
end

describe RoleControl::ParentalControlled do
  setup_role_control_tables

  let(:enrolled) { EnrolledTable.create! }
  let(:controlled) { ControlledTable.create! }
  let!(:relation) { create_role_model_instance(%w(test_parent_role test_role), controlled, enrolled)  }

  let(:tpc) { TestParentControl.new(controlled) }

  it "returns truthy when the parent's test would be true" do
    expect(tpc.can_read?(enrolled)).to be_truthy
  end

  it "returns truthy when its own role test is met" do
    expect(tpc.can_edit?(enrolled)).to be_truthy
  end

  it "should call the parent's can method if it exists" do
    expect(controlled).to receive(:can_read?)
    tpc.can_read?(enrolled)
  end
end
