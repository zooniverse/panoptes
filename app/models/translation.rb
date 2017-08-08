class Translation < ActiveRecord::Base
  include RoleControl::Controlled

  belongs_to :translated, polymorphic: true, required: true
  validate :validate_strings

  can_by_role :index, roles: [ :owner, :translator, :collaborator ]

  def self.private_query(action, target, roles)
    user_group_memberships = memberships_query(action, target)
      .select(:user_group_id)
    # check the ACL roles for projects and orgs
    # this should cover all translatable resources available
    AccessControlList
      .where(user_group_id: user_group_memberships)
      .where(resource_type: %w(Project Organization))
      .select(:resource_id)
      .where.overlap(roles: roles)
  end

  def self.user_can_access_scope(private_query, public_flag)
    # TODO: convert this to lookup projects or orgs
    # union all i guess on this but taking into account that the ids
    # from the private query may match projects / orgs we don't actually
    # have access too
    scope = where(id: private_query.select(:resource_id))
    scope = scope.or(public_scope) if public_flag
    scope
  end

  # Look at adding in paper trail change tracking for laguage / strings here

  private

  def validate_strings
    unless strings.is_a?(Hash)
      errors.add(:strings, "must be present but can be empty")
    end
  end
end
