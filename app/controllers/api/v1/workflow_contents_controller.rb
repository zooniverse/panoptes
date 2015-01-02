class Api::V1::WorkflowContentsController < Api::ApiController
  include Versioned

  doorkeeper_for :all, scopes: [:project]
  resource_actions :default
  schema_type :strong_params

  setup_access_control_for_groups!
  
  allowed_params :create, :language, strings: [], links: [:workflow]
  allowed_params :update, strings: []
end
