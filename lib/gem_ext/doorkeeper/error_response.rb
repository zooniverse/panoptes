require 'doorkeeper/oauth/error_response'

Doorkeeper::OAuth::ErrorResponse.class_eval do
  alias_method :status_without_panoptes, :status

  def status
    if %i[invalid_grant invalid_resource_owner].include?(name)
      :unauthorized
    else
      status_without_panoptes
    end
  end
end
