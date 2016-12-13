class SubjectSerializer
  include RestPack::Serializer
  include FilterHasMany

  attributes :id, :metadata, :locations, :zooniverse_id,
    :created_at, :updated_at, :href

  optional :retired, :already_seen, :finished_workflow

  can_include :project, :collections, :subject_sets

  def self.page(params = {}, scope = nil, context = {})
    scope = scope.preload(:locations, :project, :collections, :subject_sets)
    super(params, scope, context)
  end

  def locations
    @model.ordered_locations.map do |loc|
      {
       loc.content_type => loc.url_for_format(@context[:url_format] || :get)
      }
    end
  end

  def retired
    @model.retired_for_workflow?(workflow)
  end

  def already_seen
    !!(user_seen&.subjects_seen?(@model.id))
  end

  private

  def include_retired?
    select_context?
  end

  def include_already_seen?
    select_context?
  end

  def include_finished_workflow?
    select_context?
  end

  def select_context?
    @context[:select_context]
  end

  def workflow
    @context[:workflow]
  end

  def user
    @context[:user]
  end

  def user_seen
    @context[:user_seen]
  end

  def finished_workflow
    user&.has_finished?(workflow)
  end
end
