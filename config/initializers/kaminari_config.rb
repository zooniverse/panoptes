module Panoptes
  def self.page_size_limits
    @page_limits ||= { max: ENV['PAGE_SIZE_LIMIT'] || 100 }
  end

  def self.max_page_size_limit
    page_size_limits[:max]
  end
end

Kaminari.configure do |config|
  config.max_per_page = Panoptes.max_page_size_limit || nil
end
