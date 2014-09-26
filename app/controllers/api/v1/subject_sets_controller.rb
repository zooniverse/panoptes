class Api::V1::SubjectSetsController < Api::ApiController
  include JsonApiController
  
  doorkeeper_for :create, :update, :destroy, scopes: [:project]
  resource_actions :default

  allowed_params :create, :name, links: [:project,
                                           workflows: [],
                                           subjects: []]

  allowed_params :update, :name, links: [workflows: [], subjects: []]
end
