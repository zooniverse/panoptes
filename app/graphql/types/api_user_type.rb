module Types
  class ApiUserType < GraphQL::Schema::Object
    field :id, ID, null: false
    field :display_name, String, null: false
  end
end
