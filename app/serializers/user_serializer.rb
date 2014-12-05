class UserSerializer
  include RestPack::Serializer
  attributes :id, :login, :display_name, :credited_name, :email, :created_at, :updated_at,
             :owner_name
  can_include :classifications, :subjects, :project_preferences,
              projects: { param: "owner", value: "login" },
              collections: { param: "owner", value: "login" }

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
    @perrmitted ||= @context[:include_private] || 
                    (@context[:requester].logged_in? &&
                     (@model.id == @context[:requester].id) ||
                     @context[:requester].is_admin?)
  end
end
