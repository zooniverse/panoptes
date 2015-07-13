class Api::V1::TagsController < Api::ApiController
  include IndexSearch

  resource_actions :index, :show

  search_by do |name, query|
    query.search_name(name.join(" "))
  end
end
