module Versioned
  def versions
    render json_api: VersionSerializer.page(params, version_scope)
  end

  def version
    render json_api: VersionSerializer.resource(params, version_scope)
  end

  def version_scope
    PaperTrail::Version.where(item_id: controlled_resources.select(:id),
                              item_type: resource_class.to_s)
  end
end
