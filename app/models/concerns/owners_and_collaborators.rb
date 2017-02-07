module OwnersAndCollaborators
  def owners_and_collaborators
    User.joins(user_groups: :access_control_lists)
      .merge(acls.where.overlap(roles: %w(owner collaborator)))
      .select(:id)
  end
end
