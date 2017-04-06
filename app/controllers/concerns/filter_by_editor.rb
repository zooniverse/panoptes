module FilterByEditor
  extend ActiveSupport::Concern

  included do
    before_action :add_editor_ids_to_filter_param!, only: :index
  end

  def add_editor_ids_to_filter_param!
    editor_filter = params.delete(:editor).try(:split, ',')
    unless editor_filter.blank?
      editor_group_scope = UserGroup.where( UserGroup.arel_table[:name].lower.in(editor_filter.map(&:downcase)) )
      editor_scope = resource_class.filter_by_editor(editor_group_scope)
      @controlled_resources = controlled_resources.merge(editor_scope)
    end
  end
end
