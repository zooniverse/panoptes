class UserSerializer
  include RestPack::Serializer
  include RecentLinkSerializer
  include MediaLinksSerializer

  attributes :id, :login, :display_name, :credited_name, :email, :created_at,
    :updated_at, :type, :firebase_auth_token, :global_email_communication,
    :project_email_communication, :beta_email_communication,
    :slug, :max_subjects, :uploaded_subjects_count, :admin

  can_include :classifications, :project_preferences, :collection_preferences,
    projects: { param: "owner", value: "slug" },
    collections: { param: "owner", value: "slug" }

  media_include :avatar, :profile_header

  def credited_name
    permitted_value(@model.credited_name)
  end

  def email
    permitted_value(@model.email)
  end

  def global_email_communication
    permitted_value(@model.global_email_communication)
  end

  def project_email_communication
    permitted_value(@model.project_email_communication)
  end

  def beta_email_communication
    permitted_value(@model.beta_email_communication)
  end

  def firebase_auth_token
    FirebaseUserToken.generate(@model) if show_firebase_token?
  end

  def max_subjects
    permitted_value(Panoptes.max_subjects)
  end

  def uploaded_subjects_count
    permitted_value(@model.uploaded_subjects_count)
  end

  def admin
    requester ? @model.admin : false
  end

  def type
    "users"
  end

  def slug
    @model.identity_group.slug
  end

  private

  def permitted_requester?
    @permitted ||= @context[:include_private] || requester
  end

  def requester
    @context[:requester] && @context[:requester].logged_in? &&
      (@context[:requester].is_admin? || requester_is_user?)
  end

  def requester_is_user?
    @model.id == @context[:requester].id
  end

  def show_firebase_token?
    @context[:include_firebase_token] && requester_is_user?
  end

  def add_links(model, data)
    data[:links] = {}
  end

  def permitted_value(value)
    if permitted_requester?
      value
    else
      BlankTypeSerializer.default_value(value)
    end
  end
end
