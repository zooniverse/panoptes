class Api::V1::SetMemberSubjectsController < Api::ApiController
  doorkeeper_for :create, :update, :destroy, scopes: [:project]
  resource_actions :default
  schema_type :strong_params

  setup_access_control_for_groups!
  
  allowed_params :create, :priority, :state, links: [:subject, :subject_set]
  allowed_params :update, :priority, :state

  private

  def build_resource_for_create(create_params)
    update_state(create_params)
    super(create_params)
  end

  def build_resource_for_update(update_params)
    update_state(update_params)
    super(update_params)
  end

  def update_state(ps)
    if ps.has_key? :state
      ps[:state] = SetMemberSubject.states[ps[:state]]
    end
    ps
  end
end
