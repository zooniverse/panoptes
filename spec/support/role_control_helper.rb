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
    t.boolean(:private, default: true)
  end

  unless const_defined?("EnrolledActorTable")
    Object.const_set("EnrolledActorTable",
                     Class.new(ActiveRecord::Base) do
                       include RoleControl::Actor
                       
                       has_many :roles_join_tables
                     end)
  end

  unless const_defined?("ControlledTable")
    Object.const_set("ControlledTable",
                     Class.new(ActiveRecord::Base) do
                       include RoleControl::Controlled

                       has_many :roles_join_tables

                       scope :public_controlled, ->{ where(private: false) }
                       
                       can_by_role :read, :show,
                                   public: :public_controlled,
                                   role_association: :roles_join_tables,
                                   roles: [:admin, :test_role]
                       
                       can_by_role :update, roles: [:test_role],
                                   role_association: :roles_join_tables
                       
                       can_by_role :index, roles: [:admin]
                     end)
  end

  unless const_defined?("RolesJoinTable")
    Object.const_set("RolesJoinTable",
                     Class.new(ActiveRecord::Base) do
                       belongs_to :enrolled_actor_table
                       belongs_to :controlled_table
                     end)
  end
end

def create_roles_join_instance(roles, controlled_resource, actor)
  RolesJoinTable.create! do |rmt|
    rmt.roles = roles
    rmt.controlled_table = controlled_resource
    rmt.enrolled_actor_table = actor
  end
end
