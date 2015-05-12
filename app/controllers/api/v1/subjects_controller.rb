class Api::V1::SubjectsController < Api::ApiController
  include Versioned

  doorkeeper_for :update, :create, :destroy, :version, :versions,
                 scopes: [:subject]
  resource_actions :default
  schema_type :json_schema

  alias_method :subject, :controlled_resource

  def index
    case params[:sort]
    when 'queued', 'cellect' #temporary to not break compatibility with front-end
      render json_api: SubjectSerializer.page(params, *selector.queued_subjects)
    else
      super
    end
  end

  private

  def workflow
    @workflow ||= Workflow.where(id: params[:workflow_id]).first
  end

  def build_resource_for_create(create_params)
    locations = create_params.delete(:locations)
    subject = super(create_params) do |object, linked|
      object[:upload_user_id] = api_user.id
    end
    add_locations(locations, subject)
  end

  def build_update_hash(update_params, id)
    locations = update_params.delete(:locations)
    subject = Subject.find(id)
    add_locations(locations, subject)
    super(update_params, id)
  end

  def add_locations(locations, subject)
    (locations || []).each { |loc| subject.locations.build(content_type: loc) }
    subject
  end

  def context
    case action_name
    when "create", "update"
      { post_urls: true }
    else
      {}
    end
  end

  def selector
    @selector ||= SubjectSelector.new(api_user,
                                      workflow,
                                      params,
                                      controlled_resources)
  end
end
