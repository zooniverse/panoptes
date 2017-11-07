module FilterByTags
  extend ActiveSupport::Concern

  included do
    before_action :filter_by_tags, only: :index

    search_by do |name, query|
      query.search_display_name(name.join(" "))
    end

    search_by :tag do |name, query|
      query.joins(:tags).merge(Tag.search_tags(name.first))
    end
  end

  def filter_by_tags
    if tags = params.delete(:tags).try(:split, ",").try(:map, &:downcase)
      @controlled_resources = controlled_resources
      .joins(:tags).where(tags: {name: tags})
    end
  end
end
