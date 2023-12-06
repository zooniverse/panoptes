# frozen_string_literal: true

class ConfirmationsController < Devise::ConfirmationsController
  protected

  def after_confirmation_path_for(resource_name, resource)
    'https://www.zooniverse.org'
  end
end
