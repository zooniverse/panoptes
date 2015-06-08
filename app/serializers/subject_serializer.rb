class SubjectSerializer
  include RestPack::Serializer
  include FilterHasMany
  include BlankTypeSerializer

  attributes :id, :metadata, :locations, :zooniverse_id,
    :created_at, :updated_at

  optional :retired, :already_seen

  can_include :project, :collections

  def locations
    @model.locations.map do |loc|
      {
       loc.content_type => loc.url_for_format(@context[:url_format] || :get)
      }
    end
  end

  def retired
    !!(workflow && @model.set_member_subjects.first
       .retired_workflow_ids.include?(workflow.id))
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

  def selected?
    @context[:selected]
  end

  def workflow
    @context[:workflow]
  end

  def user_seen
    @context[:user_seen].try(:first)
  end
end
