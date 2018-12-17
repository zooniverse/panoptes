module Types
  class ProjectType < BaseObject
    field :id, ID, null: false
    field :display_name, String, null: false
    field :slug, String, null: false
    field :created_at, String, null: false
    field :updated_at, String,  null: false

    field :title, String, null: false
    field :description, String, null: false
    field :introduction, String, null: true
    field :workflow_description, String, null: true
    field :avatar, AvatarType, null: true

    field :private, Boolean, null: false
    field :configuration, JsonType, null: true
    field :live, Boolean, null: false
    field :migrated, Boolean, null: false
    field :slug, String, null: false
    field :redirect, String, null: true
    field :available_languages, [String], null: true
    field :primary_language, String, null: true

    field :href, String, null: true
    field :tags, [String], null: true

    field :completeness, Float, null: false
    field :activity, Integer, null: false
    field :researcher_quote, String, null: true
    field :mobile_friendly, Boolean, null: false
    # field :urls, [ProjectUrlType]
    # field :experimental_tools
    # field :state

    field :beta_requested, Boolean, null: false
    field :beta_approved, Boolean, null: false
    field :launch_requested, Boolean, null: false
    field :launch_approved, Boolean, null: false
    field :launch_date, String, null: true

    field :classifications_count, Integer, null: false
    field :retiredSubjects_count, Integer, null: false
    field :subjects_count, Integer, null: false
    field :classifiers_count, Integer, null: false
  end
end
