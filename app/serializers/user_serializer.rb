class UserSerializer
  include RestPack::Serializer
  include RecentLinkSerializer

  attributes :id, :display_name, :credited_name, :email, :created_at,
             :updated_at, :type, :firebase_auth_token
  can_include :classifications, :project_preferences, :collection_preferences,
              projects: { param: "owner", value: "display_name" },
              collections: { param: "owner", value: "display_name" }

  can_filter_by :display_name

  def credited_name
    @model.credited_name if permitted_requester?
  end

  def email
    @model.email if permitted_requester?
  end

  def firebase_auth_token
    FirebaseUserToken.generate(@model) if show_firebase_token?
  end

  def type
    "users"
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
