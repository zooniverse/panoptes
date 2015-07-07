class UserProjectPreferenceSerializer
  include RestPack::Serializer
  attributes :id, :email_communication, :preferences, :href, :activity_count
  can_include :user, :project

  def self.key
    "project_preferences"
  end

  def activity_count
    @model.activity_count || UserSeenSubject.count_user_activity(@model.user_id)
  end
end
