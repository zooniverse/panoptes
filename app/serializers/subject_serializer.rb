class SubjectSerializer
  include RestPack::Serializer
  include FilterHasMany

  attributes :id, :metadata, :locations, :zooniverse_id,
    :created_at, :updated_at, :href

  optional :retired, :already_seen, :finished_workflow

  can_include :project, :collections, :subject_sets

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
    !!(user_seen && user_seen.subject_ids.include?(@model.id))
  end

  private

  def include_retired?
    selected?
  end

  def include_already_seen?
    selected?
  end

  def include_finished_workflow?
    selected?
  end

  def selected?
    @context[:selected]
  end

  def workflow
    @context[:workflow]
  end

  def user_seen
    @context[:user_seen].try(:first)
  end

  def finished_workflow
    @context[:finished_workflow]
  end
end
