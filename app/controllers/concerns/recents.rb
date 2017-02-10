module Recents
  def recents
    ps = params.dup
    ps.delete "#{resource_name}_id"
    render json_api: RecentSerializer.page(
      ps,
      Recent.where(:"#{resource_name}_id" => resource_ids),
      { type: resource_sym.to_s, owner_id: resource_ids }
    )
  end
end
