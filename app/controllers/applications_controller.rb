class ApplicationsController < Doorkeeper::ApplicationsController
  skip_before_filter :authenticate_admin!
  before_filter :authenticate_user!
  before_action :add_public_scope, only: [:create, :update]

  respond_to :html

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
      respond_with :oauth, @application, location: oauth_application_url( @application )
    else
      render :new
    end
  end

  def update
    if @application.update!(application_params)
      flash[:notice] = I18n.t(:notice, scope: [:doorkeeper, :flash, :applications, :update])
      respond_with :oauth, @application, location: oauth_application_url( @application )
    else
      render :edit
    end
  end

  def add_public_scope
    application_params[:default_scope] ||= []
    application_params[:default_scope] << "public"
  end

  def application_params
    @application_params ||= params.require(:application).permit(:name, :redirect_uri, default_scope: [])
  end
end
