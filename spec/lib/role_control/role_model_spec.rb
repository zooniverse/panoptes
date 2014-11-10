require 'spec_helper'

describe RoleControl::RoleModel do
  setup_role_control_tables
  let(:subject) { RolesJoinTable }
  let(:enrolled_actor) { EnrolledActorTable.create! }
  let(:controlled) { ControlledTable.create! }

  # Tests RolesJoinTable as defined in
  # spec/support/role_control_helpers.rb

  describe "::roles_for" do
    it 'should set the role query variable' do
      expect(subject.instance_variable_get(:@role_query)).to be_a(RoleControl::RoleQuery)
    end

    it 'should set the roles field variable' do
      expect(subject.instance_variable_get(:@roles_field)).to eq(:roles)
    end

    it 'should set the valid roles variable' do
      valid_roles = %w(admin test_role test_parent_role)
      expect(subject.instance_variable_get(:@valid_roles)).to eq(valid_roles)
    end

  end

  describe "::roles_query" do
    it 'should call role_query with the given actor and resources' do
      query_obj = subject.instance_variable_get(:@role_query)
      expect(query_obj).to receive(:build).with(nil, nil)
      subject.roles_query
    end
  end

  let(:role_model) { subject.new }

  it 'should validate allowed roles' do
    role_model.roles = ["test_rolo"]
    expect(role_model).to_not be_valid

    role_model.roles = ["admin"]
    expect(role_model).to be_valid
  end
end
