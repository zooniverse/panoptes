module Recents
  def recents
    ps = params.dup
    ps.delete "#{resource_name}_id"
    DatabaseReplica.read("read_recents_from_read_slave") do
      render json_api: RecentSerializer.page(
        ps,
        Recent.where(:"#{resource_name}_id" => resource_ids),
        { url_prefix: "#{resource_sym.to_s.pluralize}/#{resource_ids}" }
      )
    end
  end
end
