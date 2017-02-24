module Recents
  def recents
    ps = params.dup
    ps.delete "#{resource_name}_id"
    render json_api: RecentSerializer.page(
      ps,
      Recent.where(:"#{resource_name}_id" => resource_ids),
      { url_prefix: "#{resource_sym.to_s.pluralize}/#{resource_ids}" }
    )
  end
end
