module FilterByDisplayName
  extend ActiveSupport::Concern

  included do
    before_action :filter_by_display_name, only: :index
  end

  def filter_by_display_name
    if display_name = params.delete(:display_name)
      query = display_name.last == "*" ? display_name[0..-2] + '%' : display_name
      @controlled_resources = controlled_resources.where('"display_name" ILIKE ?', query)
    end
  end
end
