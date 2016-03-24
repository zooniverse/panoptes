class ApiUser
  include RoleControl::Actor

  attr_reader :user

  delegate :memberships_for, :owns?, :id, :languages, :user_groups,
    :project_preferences, :collection_preferences, :classifications,
    :user_groups, :has_finished?, :memberships, :upload_whitelist,
    to: :user, allow_nil: true

  def initialize(user, admin: false)
    @user, @admin_flag = user, admin
  end

  def logged_in?
    !!user
  end

  def owner
    user
  end

  def is_admin?
    logged_in? && user.is_admin? && @admin_flag
  end

  def banned?
    logged_in? && user.banned
  end

  def above_subject_limit?
    return false if is_admin? || upload_whitelist
    current, max = subject_limits
    current >= max
  end

  def subject_limits
    [user.uploaded_subjects_count, user.subject_limit]
  end
end
