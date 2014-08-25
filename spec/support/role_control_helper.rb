def setup_role_control_tables
  mock_active_record_model(:enrolled) do |t|
    t.string(:a_field)
  end

  mock_active_record_model(:role_model) do |t|
    t.string(:roles, array: true, default: [], null: false)
    t.integer(:enrolled_table_id)
    t.integer(:controlled_table_id)
  end

  mock_active_record_model(:controlled) do |t|
    t.string(:another_field)
    t.string(:visible_to, array: true, default: [], null: false)
  end

  EnrolledTable.class_eval do
    include RoleControl::Enrolled
    
    has_many :role_model_tables
    enrolled_for :controlled_tables, through: :role_model_tables
  end
  
  ControlledTable.class_eval do
    include RoleControl::Controlled
    
    can_by_role :read, public: true, roles: :visible_to
    can_by_role :update, roles: [:test_role]
    can_by_role :index, roles: [:admin]
  end

  RoleModelTable.class_eval do
    include RoleControl::RoleModel
    belongs_to :enrolled_table
    belongs_to :controlled_table

    roles_for :enrolled_table, :controlled_table,
      valid_roles: [ :admin, :test_role, :test_parent_role]
  end
end

def create_role_model_instance(roles, controlled_resource, actor)
  RoleModelTable.create! do |rmt|
    rmt.roles = roles
    rmt.controlled_table = controlled_resource
    rmt.enrolled_table = actor
  end
end
