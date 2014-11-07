module JsonApiController
  extend ActiveSupport::Concern

  included do
    @action_params = Hash.new
  end

  module ClassMethods
    def resource_actions(*actions)
      if actions.first == :default
        actions = [:show, :index, :create, :update, :destroy]
      end
      
      actions.each do |action|
        case action
        when :show
          include JsonApiController::ShowableResource
        when :index
          include JsonApiController::IndexableResource
        when :create
          include JsonApiController::CreatableResource
        when :update
          include JsonApiController::UpdatableResource
        when :destroy
          include JsonApiController::DestructableResource
        when :deactivate
          include JsonApiController::DeactivatableResource
        end
      end
    end

    def allowed_params(action, *request_description)
      @action_params[action] = request_description
    end

    def action_params
      @action_params
    end

    protected

    def polymorphic
      [ :id, :type ]
    end
  end

  def current_actor
    owner_from_params || api_user
  end
  
  def serializer
    @serializer ||= "#{ resource_name.camelize }Serializer".constantize
  end

  def resource_name
    @resource_name ||= self.class.name
      .match(/::([a-zA-Z]*)Controller/)[1].underscore.singularize
  end

  def resource_sym
    resource_name.pluralize.to_sym
  end

  def resource_class
    @resource_class ||= resource_name.camelize.constantize
  end

  def visible_scope
    super(api_user)
  end

  def params_for(action)
    params.require(resource_sym).permit(*self.class.action_params[action])
  end

  def create_params
    params_for(:create)
  end

  def update_params
    params_for(:update)
  end

  def context
    {}
  end
end
