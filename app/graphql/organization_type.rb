OrganizationType = GraphQL::ObjectType.define do
  name "Organization"
  description "Organizations allow grouping of projects."

  field :id, !types.ID
  field :displayName, !types.String, property: :display_name
  field :slug, !types.String

  field :classificationsCount, !types.Int do
    description "Aggregated number of classifications across all projects."
    resolve ->(obj, args, ctx) {
      obj.projects.sum(:classifications_count)
    }
  end

  field :retiredSubjectsCount, !types.Int, property: :retired_subjects_count do
    description "Aggregated number of retired subjects across all projects."
  end

  field :projects, types[ProjectType] do
    argument :tags, types[types.String], "Filter by tags. If multiple specified, then returns projects that have any of the specified tags"

    resolve ->(obj, args, ctx) {
      scope = obj.projects.where(private: false).preload(:project_contents)
      scope = scope.joins(:tags).where(tags: {name: args[:tags].map(&:downcase)}) if args[:tags].present?
      scope
    }
  end
end
