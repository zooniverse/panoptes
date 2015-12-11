def setup_role_control_tables
  mock_active_record_model(:controlled) do |t|
    t.string(:another_field)
    t.boolean(:private, default: true)
  end

  mock_active_record_model(:test_parent_control) do |t|
    t.integer(:controlled_table_id)
  end

  unless const_defined?("ControlledTable")
    Object.const_set("ControlledTable",
                     Class.new(ActiveRecord::Base) do
                       include RoleControl::Controlled

                       has_many :access_control_lists, as: :resource

                       can_by_role :read, :show,
                                   public: true,
                                   roles: [:admin, :test_role]

                       can_by_role :update, roles: [:test_role]

                       can_by_role :index, roles: [:admin]
                     end)
  end

  unless const_defined?("TestParentControlTable")
    Object.const_set("TestParentControlTable",
                     Class.new(ActiveRecord::Base) do
                       include RoleControl::ParentalControlled

                       can_through_parent :controlled_table, :index, :read, :show, :update
                     end)
  end
end

def create_roles_join_instance(roles, controlled_resource, actor)
  AccessControlList.create! do |rmt|
    rmt.roles = roles
    rmt.resource = controlled_resource
    rmt.user_group = actor.identity_group
  end
end
