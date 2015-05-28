class UserSerializer
  include RestPack::Serializer
  include RecentLinkSerializer
  include MediaLinksSerializer

  attributes :id, :display_name, :credited_name, :email, :created_at,
    :updated_at, :type, :firebase_auth_token, :global_email_communication,
    :slug
  can_include :classifications, :project_preferences, :collection_preferences,
    projects: { param: "owner", value: "slug" },
    collections: { param: "owner", value: "slug" }

  media_include :avatar

  def credited_name
    permitted_requester? ? @model.credited_name : ""
  end

  def email
    permitted_requester? ? @model.email : ""
  end

  def global_email_communication
    @model.global_email_communication if permitted_requester?
  end

  def firebase_auth_token
    FirebaseUserToken.generate(@model) if show_firebase_token?
  end

  def type
    "users"
  end

  def slug
    @model.identity_group.slug
  end

  private

  def permitted_requester?
    @perrmitted ||= @context[:include_private] || requester
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
end
