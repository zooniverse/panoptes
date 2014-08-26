def setup_role_control_tables
  mock_active_record_model(:enrolled_actor) do |t|
    t.string(:a_field)
  end

  mock_active_record_model(:roles_join) do |t|
    t.string(:roles, array: true, default: [], null: false)
    t.integer(:enrolled_actor_table_id)
    t.integer(:controlled_table_id)
  end

  mock_active_record_model(:controlled) do |t|
    t.string(:another_field)
    t.string(:visible_to, array: true, default: [], null: false)
  end

  EnrolledActorTable.class_eval do
    include RoleControl::Enrolled
    
    has_many :roles_join_tables
    enrolled_for :controlled_tables, through: :roles_join_tables
  end
  
  ControlledTable.class_eval do
    include RoleControl::Controlled
    
    can_by_role :read, public: true, roles: :visible_to
    can_by_role :update, roles: [:test_role]
    can_by_role :index, roles: [:admin]
  end

  RolesJoinTable.class_eval do
    include RoleControl::RoleModel
    belongs_to :enrolled_actor_table
    belongs_to :controlled_table

    roles_for :enrolled_actor_table, :controlled_table,
      valid_roles: [ :admin, :test_role, :test_parent_role]
  end
end

def create_roles_join_instance(roles, controlled_resource, actor)
  RolesJoinTable.create! do |rmt|
    rmt.roles = roles
    rmt.controlled_table = controlled_resource
    rmt.enrolled_actor_table = actor
  end
end
