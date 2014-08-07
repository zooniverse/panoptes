def setup_role_control_tables
  mock_active_record_model(:role_model) do |t|
    t.string(:a_field)
  end

  mock_active_record_model(:membership) do |t|
    t.string(:roles, array: true, default: [], null: false)
    t.integer(:role_model_table_id)
    t.integer(:group_table_id)
  end

  mock_active_record_model(:group) do |t|
    t.string(:another_field)
    t.string(:visible_to, array: true, default: [], null: false)
  end

  RoleModelTable.class_eval do
    include RoleControl::Enrolled
    
    has_many :membership_tables
    has_many :group_tables, through: :membership_tables

    roles_for GroupTable, :membership_tables
  end
  
  GroupTable.class_eval do
    extend RoleControl::Controlled
    can_by_role :read, :test_role
  end
end
