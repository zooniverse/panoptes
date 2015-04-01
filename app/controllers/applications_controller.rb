class ApplicationsController < Doorkeeper::ApplicationsController
  before_filter :authenticate_user!

  def index
    if current_user.is_admin?
      @applications = Doorkeeper::Application.all 
    else
      @applications = current_user.oauth_applications
    end
  end

  def create
    @application = Doorkeeper::Application.new(application_params)
    @application.owner = current_user if Doorkeeper.configuration.confirm_application_owner?
    if @application.save
      flash[:notice] = I18n.t(:notice, :scope => [:doorkeeper, :flash, :applications, :create])
       respond_with( :oauth, @application, location: oauth_application_url( @application ) )
    else
      render :new
    end
  end

  def application_params
    params.require(:application).permit(:name, :redirect_uri, default_scope: [])
  end
end
