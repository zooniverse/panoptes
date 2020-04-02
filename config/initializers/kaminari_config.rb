Kaminari.configure do |config|
  config.max_per_page = ENV.fetch('PAGE_SIZE_LIMIT', 100)
end
