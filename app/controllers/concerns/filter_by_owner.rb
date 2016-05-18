module FilterByOwner
  extend ActiveSupport::Concern

  included do
    before_action :add_owner_ids_to_filter_param!, only: :index
  end

  def add_owner_ids_to_filter_param!
    owner_filter = params.delete(:owner).try(:split, ',')
    unless owner_filter.blank?
      owner_group_scope = UserGroup.where(
        UserGroup.arel_table[:name].lower.in(owner_filter.map(&:downcase))
      )
      owner_scope = resource_class.filter_by_owner(owner_group_scope)
      @controlled_resources = controlled_resources.merge(owner_scope)
    end
  end
end
