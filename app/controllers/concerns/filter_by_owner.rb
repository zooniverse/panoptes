module FilterByOwner
  extend ActiveSupport::Concern

  included do
    before_action :add_owner_ids_to_filter_param!, only: :index
  end

  def add_owner_ids_to_filter_param!
    owner_filter = params.delete(:owner).try(:split, ',')
    unless owner_filter.blank?
      groups = UserGroup.where(UserGroup.arel_table[:name].lower.in(owner_filter.map(&:downcase)))
      @controlled_resources = controlled_resources
        .eager_load(:owner)
        .joins(:owner)
        .joins(:access_control_lists)
        .where(access_control_lists: {user_group: groups})
        .where.overlap(access_control_lists: { roles: ["owner"] })
    end
  end
end
