class SubjectSelectorSerializer
  include Serialization::PanoptesRestpack
  include NoCountSerializer

  attributes :id, :metadata, :locations, :zooniverse_id,
    :created_at, :updated_at, :href

  optional :retired, :already_seen, :finished_workflow,
    :user_has_finished_workflow, :favorite, :selection_state

  preload :locations

  def self.model_class
    Subject
  end

  def locations
    @model.ordered_locations.map do |loc|
      {
       loc.content_type => loc.url_for_format(@context[:url_format] || :get)
      }
    end
  end

  def retired
    @context[:retired_subject_ids].include? @model.id
  end

  def already_seen
    @context[:user_seen_subject_ids].include?(@model.id)
  end

  def finished_workflow
    @context[:finished_workflow]
  end

  def user_has_finished_workflow
    @context[:user_has_finished_workflow]
  end

  def favorite
    @context[:favorite_subject_ids].include?(@model.id)
  end

  def selection_state
    @context[:selection_state]
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

  def include_user_has_finished_workflow?
    select_context?
  end

  def include_favorite?
    select_context?
  end

  def include_selection_state?
    select_context?
  end

  def select_context?
    !!@context[:select_context]
  end
end
