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
    @model.locations.order("\"media\".\"metadata\"->>'index' ASC").map do |loc|
      {
       loc.content_type => loc.url_for_format(@context[:url_format] || :get)
      }
    end
  end

  def retired
    @model.retired_for_workflow?(workflow)
  end

  def already_seen
    !!(user_seen&.subject_ids.include?(@model.id))
  end

  private

  def include_retired?
    enabled_selection_context
  end

  def include_already_seen?
    enabled_selection_context
  end

  def include_finished_workflow?
    enabled_selection_context
  end

  def enabled_selection_context
    selected? && !Panoptes.flipper[:skip_subject_selection_context].enabled?
  end

  def selected?
    @context[:selected]
  end

  def workflow
    @context[:workflow]
  end

  def user
    @context[:user]
  end

  def user_seen
    @user_seen ||= UserSeenSubject.where(user: user, workflow: workflow).first
  end

  def finished_workflow
    user&.has_finished?(workflow)
  end
end
