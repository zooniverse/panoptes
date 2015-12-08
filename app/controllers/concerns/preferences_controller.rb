module PreferencesController
  extend ActiveSupport::Concern

  included do
    prepend_before_filter :require_login

    resource_actions :index, :show, :create, :update

    include CreateOverride
  end

  def resource_class
    @resource_class ||= "User#{resource_name.camelize}".constantize
  end

  def serializer
    @serialier ||= "User#{resource_name.camelize}Serializer".constantize
  end

  module CreateOverride
    def build_resource_for_create(create_params)
      create_params[:links][:user] = api_user.user
      super(create_params)
    end
  end
end
