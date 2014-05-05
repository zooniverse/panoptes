module Oauth
  class ApplicationsController < Doorkeeper::ApplicationsController
    before_action :authenticate_user!

    def index
      @applications = current_user.oauth_applications
    end 

    def create
      @application = Doorkeeper::Application.new(application_params)
      @application.owner = current_user 
      if @application.save
        flash[:node] = I18n.t(:notice, scope: [:doorkeeper, :flash, :applications, :create])
        respond_with [:oauth, @application]
      else
        render :new
      end
    end

  end
end
