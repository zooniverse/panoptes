class SubjectSerializer
  include RestPack::Serializer
  include FilterHasMany

  attributes :id, :metadata, :locations, :zooniverse_id,
    :created_at, :updated_at

  attribute :retired, if: :selected?
  attribute :already_seen, if: :selected?
  can_include :project, :collections

  def locations
    @model.locations.map do |loc|
      {
       loc.content_type => @context[:post_urls] ? loc.put_url : loc.get_url
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
