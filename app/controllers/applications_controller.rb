class ApplicationsController < Doorkeeper::ApplicationsController
  skip_before_action :authenticate_admin!
  before_action :authenticate_user!
  before_action :add_public_scope, only: [:create, :update]

  respond_to :html

  def index
    @applications = scope_for_current_user
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
    if @application.update(application_params)
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

  def set_application
    @application = scope_for_current_user.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    head 404
  end

  def scope_for_current_user
    if current_user.is_admin?
      Doorkeeper::Application.all
    else
      current_user.oauth_applications
    end
  end
end
