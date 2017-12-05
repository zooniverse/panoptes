require 'json'

JsonType = GraphQL::ScalarType.define do
  name "JsonType"
  description "Arbitrary JSON object"

  coerce_input ->(value, ctx) { value }
  coerce_result ->(value, ctx) { value }
end
