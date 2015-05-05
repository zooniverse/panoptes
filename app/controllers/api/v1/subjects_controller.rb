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

  def context
    case action_name
    when "update", "create"
      { post_urls: true }
    else
      { }
    end
  end

  def workflow
    @workflow ||= Workflow.where(id: params[:workflow_id]).first
  end

  def build_resource_for_create(create_params)
    locations = create_params.delete(:locations)
    subject = super(create_params) do |object, linked|
      object[:upload_user_id] = api_user.id
    end
    locations.each do |loc|
      subject.locations.build(content_type: loc)
    end
    subject
  end

  def selector
    @selector ||= SubjectSelector.new(api_user,
                                      workflow,
                                      params,
                                      controlled_resources)
  end
end
