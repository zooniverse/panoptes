class UserProjectPreferenceSerializer
  include RestPack::Serializer
  include BlankTypeSerializer
  attributes :id, :email_communication, :preferences
  can_include :user, :project

  def self.key
    "project_preferences"
  end
end
