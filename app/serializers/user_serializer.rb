class UserSerializer
  include RestPack::Serializer
  attributes :id, :login, :display_name, :credited_name, :owner_name, :created_at, :updated_at
  can_include :projects, :collections, :classifications, :subjects, :project_preferences

  def owner_name
    @model.owner_uniq_name
  end
end
