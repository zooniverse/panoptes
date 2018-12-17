module Types
  class OrganizationType < BaseObject
    description "Organizations allow grouping of projects."

    field :id, ID, null: false
    field :display_name, String, null: false
    field :slug, String, null: false
    field :classifications_count, Integer, null: false, description: "Aggregated number of classifications across all projects."
    field :retired_subjects_count, Integer, null: false, description: "Aggregated number of retired subjects across all projects."
    field :projects, [ProjectType], null: false do
      argument :tags, [String], required: false, description: "Filter by tags. If multiple specified, then returns projects that have any of the specified tags"
    end

    def classifications_count
      object.projects.sum(:classifications_count)
    end

    def projects(tags: [])
      scope = object.projects.where(private: false).preload(:project_contents)
      scope = scope.joins(:tags).where(tags: {name: tags.map(&:downcase)}) if tags.present?
      scope
    end
  end
end
