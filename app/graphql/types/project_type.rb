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
    field :urls, [Types::UrlType], null: false,
      description: "List of external websites associated with this project, like
      blogs and social media accounts."

    field :private, Boolean, null: false
    field :configuration, GraphQL::Types::JSON, null: true
    field :live, Boolean, null: false
    field :migrated, Boolean, null: false
    field :slug, String, null: false
    field :redirect, String, null: true,
      description: "If set, this project is hosted on an external domain rather
      than as a standard project on our own site."
    field :available_languages, [String], null: true
    field :primary_language, String, null: true
    field :tags, [String], null: true

    field :completeness, Float, null: false
    field :activity, Integer, null: false
    field :researcher_quote, String, null: true
    field :mobile_friendly, Boolean, null: false
    field :experimental_tools, [String], null: false,
      description: "Enabled beta or otherwise experimental/project-specific
      features. The backend does not enforce what valid elements of this list
      are, refer to frontend documentation to find out what experimental tools
      we have at the moment."
    field :state, Types::ProjectState, null: false

    field :beta_requested, Boolean, null: false,
      description: "Project owner has requested that this project is sent to our beta-testing mailing list"
    field :beta_approved, Boolean, null: false,
      description: "We have run a beta for this project and approved it for a wider launch"
    field :launch_requested, Boolean, null: false,
      description: "Project owner has addressed any minor comments from the beta stage and prepared the project for full launch"
    field :launch_approved, Boolean, null: false,
      description: "We have fully launched this project"
    field :launch_date, String, null: true,
      description: "If launchApproved is true, this field will indicate when we launched this project, otherwise this will be null"

    field :classifications_count, Integer, null: false
    field :retiredSubjects_count, Integer, null: false
    field :subjects_count, Integer, null: false
    field :classifiers_count, Integer, null: false

    def urls
      urls = object.urls.dup
      TasksVisitors::InjectStrings.new(object.url_labels).visit(urls)
      urls
    end
  end
end
