class GraphqlController < ApplicationController
  def execute
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {api_user: api_user}
    result = GraphqlSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  end

  private

  def current_resource_owner
    if doorkeeper_token
      @current_resource_owner ||= User.find_by_id(doorkeeper_token.resource_owner_id)
    elsif current_user
      current_user
    end
  end

  def api_user
    @api_user ||= ApiUser.new(current_resource_owner, admin: admin_flag?)
  end

  def admin_flag?
    false
  end

  # Handle form data, JSON body, or a blank value
  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end
end
