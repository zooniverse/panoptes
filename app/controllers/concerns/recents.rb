module Recents
  def recents
    ps = params.dup
    ps.delete "#{resource_name}_id"
    read_recents_from_database do
      render json_api: RecentSerializer.page(
        ps,
        Recent.where(:"#{resource_name}_id" => resource_ids),
        { url_prefix: "#{resource_sym.to_s.pluralize}/#{resource_ids}" }
      )
    end
  end

  private

  def read_recents_from_database
    if Panoptes.flipper.enabled?("read_recents_from_read_slave")
      Slavery.on_slave do
        yield
      end
    else
      yield
    end
  end
end
