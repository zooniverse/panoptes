module Types
   class ApiUserType < BaseObject
    field :id, ID, null: false
    field :display_name, String, null: false
  end
end
