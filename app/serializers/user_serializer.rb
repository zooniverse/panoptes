class UserSerializer
  include RestPack::Serializer
  include RecentLinkSerializer
  include MediaLinksSerializer

  attributes :id, :login, :display_name, :credited_name, :email, :created_at,
    :updated_at, :type, :global_email_communication,
    :project_email_communication, :beta_email_communication,
    :max_subjects, :uploaded_subjects_count, :admin, :href, :login_prompt,
    :private_profile, :zooniverse_id, :upload_whitelist

  can_include :classifications, :project_preferences, :collection_preferences,
    projects: { param: "owner", value: "login" },
    collections: { param: "owner", value: "login" }

  media_include :avatar, :profile_header

  def max_subjects
    @model.subject_limit
  end

  def admin
    !!@model.admin
  end

  def type
    "users"
  end

  def login_prompt
    @model.migrated && @model.sign_in_count <= 1
  end

  private

  def permitted_requester?
    @permitted ||= @context[:include_private] || requester
  end

  %w(credited_name email global_email_communication project_email_communication
     beta_email_communication uploaded_subjects_count max_subjects admin
     login_prompt zooniverse_id, upload_whitelist).each do |me_only_attribute|
    alias_method :"include_#{me_only_attribute}?", :permitted_requester?
  end

  def requester
    @context[:requester] && @context[:requester].logged_in? &&
      (@context[:requester].is_admin? || requester_is_user?)
  end

  def requester_is_user?
    @model.id == @context[:requester].id
  end

  def add_links(model, data)
    data[:links] = {}
  end
end
