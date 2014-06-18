class Api::V1::RegistrationsController < Api::ApiController

  class RegistrationError < StandardError; end

  # doorkeeper_for :index, :me, :show, scopes: [:public]
  # doorkeeper_for :update, :destroy, scopes: [:user]
  #
  # after_action :verify_authorized, except: :index

  def new
    not_supported
  end

  def edit
    not_supported
  end

  def destroy
    not_supported
  end

  def update
    not_supported
  end

  def create
  end

  private

    def not_supported
      not_found(RegistrationError.new("Nothing to see here...move along now."))
    end
end
