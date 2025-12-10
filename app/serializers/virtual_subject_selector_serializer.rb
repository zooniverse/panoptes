# frozen_string_literal: true

class VirtualSubjectSelectorSerializer
  include Serialization::PanoptesRestpack

  attributes :id, :metadata, :locations, :zooniverse_id,
    :created_at, :updated_at, :href, :selected_at

  optional :retired, :already_seen, :finished_workflow,
    :user_has_finished_workflow, :favorite, :selection_state

  def self.key
    'subjects'
  end

  def self.associations
    []
  end

  def self.can_includes
    []
  end

  def self.page(params = {}, scope = nil, context = {})
    items = Array(scope)
    page = params.fetch(:page, 1).to_i
    page = 1 if page < 1
    page_size = params[:page_size].to_i
    page_size = items.length if page_size <= 0

    offset = (page - 1) * page_size
    page_items = items.slice(offset, page_size) || []

    resources = page_items.map { |model| as_json(model, context) }

    meta = {
      page: page,
      page_size: page_size,
      count: items.length,
      include: [],
      page_count: 0,
      previous_page: page - 1,
      next_page: page_items.empty? ? nil : page + 1,
      first_href: nil,
      previous_href: nil,
      next_href: nil,
      last_href: nil
    }


    { key.to_sym => resources, links: {}, meta: { key.to_sym => meta } }
  end

  def locations
    @model.ordered_locations.map do |loc|
      { loc.content_type => loc.url_for_format(@context[:url_format] || :get) }
    end
  end

  def href
    nil
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

  def selected_at
    @context[:selected_at]
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
