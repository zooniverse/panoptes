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

  let(:role_model) { rt = RoleModelTable.new; rt.save!; rt }
  let(:group_table) { gt = GroupTable.new; gt.save!; gt }
  let!(:relation) do
    m = MembershipTable.new
    m.roles = ['test_parent_role', 'test_role']
    m.role_model_table_id = role_model.id
    m.group_table_id = group_table.id
    m.save!
  end

  let(:tpc) { TestParentControl.new(group_table) }

  it "returns true when the parent's test would be true" do
    expect(tpc.can_read?(role_model)).to be_truthy
  end

  it "returns true when its own role test is met" do
    expect(tpc.can_edit?(role_model)).to be_truthy
  end

  it "should call the parent's can method if it exists" do
    expect(group_table).to receive(:can_read?)
    tpc.can_read?(role_model)
  end
end
