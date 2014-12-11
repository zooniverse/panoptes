class UserSerializer
  include RestPack::Serializer
  attributes :id, :login, :display_name, :credited_name, :email, :created_at, :updated_at,
             :owner_name
  can_include :classifications, :subjects, :project_preferences,
              projects: { param: "owner", value: "owner_name" },
              collections: { param: "owner", value: "owner_name" }

  can_filter_by :login

  def credited_name
    @model.credited_name if permitted_requester?
  end

  def email
    @model.email if permitted_requester?
  end

  def owner_name
    @model.owner_uniq_name
  end

  private

  def permitted_requester?
    @perrmitted ||= @context[:include_private] || requester

  end

  def requester
    @context[:requester] && @context[:requester].logged_in? &&
    (@context[:requester].is_admin? || @model.id == @context[:requester].id)
  end
end
