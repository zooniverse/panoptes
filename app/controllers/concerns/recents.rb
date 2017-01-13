module Recents
  def recents
    ps = params.dup
    ps.delete "#{resource_name}_id"
    render json_api: RecentSerializer.page(ps, recent_scope, { type: resource_sym.to_s, owner_id: resource_ids })
  end

  def recent_scope
    scope = Recent.where(:"#{resource_name}_id" => resource_ids)
    scope = scope.where(project_id: params[:project_id]) if params.key?(:project_id)
    scope = scope.where(workflow_id: params[:workflow_id]) if params.key?(:workflow_id)
    scope
  end
end
