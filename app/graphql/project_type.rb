ProjectType = GraphQL::ObjectType.define do
  name "Project"

  field :id, !types.ID
  field :displayName, !types.String, property: :display_name
  field :slug, !types.String
  field :createdAt, !types.String, property: :created_at
  field :updatedAt, !types.String, property: :updated_at

  field :title, !types.String, resolve: ->(obj, args, ctx) { obj.primary_content.title }
  field :description, !types.String, resolve: ->(obj, args, ctx) { obj.primary_content.description }
  field :introduction, types.String, resolve: ->(obj, args, ctx) { obj.primary_content.introduction }
  field :workflowDescription, types.String, property: :workflow_description, resolve: ->(obj, args, ctx) { obj.primary_content.workflow_description }
  field :avatar, AvatarType

  field :private, !types.Boolean
  field :configuration, JsonType
  field :live, !types.Boolean
  field :migrated, !types.Boolean
  field :slug, !types.String
  field :redirect, types.String
  field :availableLanguages, types[types.String], property: :available_languages
  field :primaryLanguage, types.String, property: :primary_language

  field :href, types.String
  field :tags, types[types.String]

  field :completeness, !types.Float
  field :activity, !types.Int
  field :researcher_quote, types.String
  field :mobile_friendly, !types.Boolean
  # field :urls, types[ProjectUrlType]
  # field :experimental_tools
  # field :state

  field :betaRequested, !types.Boolean, property: :beta_requested
  field :betaApproved, !types.Boolean, property: :beta_approved
  field :launchRequested, !types.Boolean, property: :launch_requested
  field :launchApproved, !types.Boolean, property: :launch_approved
  field :launchDate, types.String, property: :launch_date

  field :classificationsCount, !types.Int, property: :classifications_count
  field :retiredSubjectsCount, !types.Int, property: :retired_subjects_count
  field :subjects_count, !types.Int, property: :subjects_count
  field :classifiers_count, !types.Int, property: :classifiers_count
end
