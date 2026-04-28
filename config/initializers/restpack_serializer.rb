# frozen_string_literal: true

Rails.application.config.to_prepare do
  Dir[Rails.root.join('app/serializers/**/*.rb')].sort.each do |path|
    require path
  end

  RestPack::Serializer.setup do |config|
    config.page_size = 20
  end
end
