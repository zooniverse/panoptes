class Api::V1::RegistrationsController < Devise::RegistrationsController

  #TODO: Extract out the API controller funcationlity to a helper
  include JSONApiRender
  respond_to :json

  def create
    render status: :not_found, json_api: {}
  end
end
