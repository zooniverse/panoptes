require 'ostruct'
cors_config = ActiveSupport::HashWithIndifferentAccess.new.tap do |cors|
  cors[:request_headers] = :any
  cors[:request_methods] = %i(delete get post options put head)
  cors[:expose_headers] = %w(ETag)
  cors[:max_age] = 300
end
CorsConfig = OpenStruct.new(cors_config)
