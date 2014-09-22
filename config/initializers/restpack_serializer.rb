Dir[Rails.root.join('app/serializers/**/*.rb')].each do |path|
  require path
end

RestPack::Serializer.setup do |config|
  config.page_size = 20
end
