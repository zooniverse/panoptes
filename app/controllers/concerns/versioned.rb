module Versioned
  extend ActiveSupport::Concern

  included do
    access_control_for [:versions, :show], [:version, :show]
  end

  def versions
    render json_api: VersionSerializer.page(params, controlled_resource.versions)
  end

  def version
    render json_api: VersionSerializer.resource(params, controlled_resource.versions)
  end
end
