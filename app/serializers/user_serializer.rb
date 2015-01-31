class UserSerializer
  include RestPack::Serializer
  attributes :id, :login, :display_name, :credited_name, :email, :created_at, :updated_at, :type
  can_include :classifications, :project_preferences, :collection_preferences,
              projects: { param: "owner", value: "login" },
              collections: { param: "owner", value: "login" }

  can_filter_by :login

  def credited_name
    @model.credited_name if permitted_requester?
  end

  def email
    @model.email if permitted_requester?
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
      (@context[:requester].is_admin? || @model.id == @context[:requester].id)
  end

  def add_links(model, data)
    data[:links] = {}
  end
end
