module Panoptes
  def self.page_size_limits
    @page_limits ||= begin
                       file = Rails.root.join('config/page_size_limits.yml')
                       YAML.load(File.read(file))[Rails.env].symbolize_keys
                     rescue Errno::ENOENT, NoMethodError
                       {  }
                     end
  end

  def self.max_page_size_limit
    page_size_limits[:max]
  end
end

Kaminari.configure do |config|
  config.max_per_page = Panoptes.max_page_size_limit || nil
end
