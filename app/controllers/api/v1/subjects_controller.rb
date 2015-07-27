class Api::V1::SubjectsController < Api::ApiController
  include Versioned

  doorkeeper_for :update, :create, :destroy, :version, :versions,
                 scopes: [:subject]
  resource_actions :default
  schema_type :json_schema

  alias_method :subject, :controlled_resource

  before_action :check_subject_limit, only: :create

  def index
    case params[:sort]
    when 'queued', 'cellect' #temporary to not break compatibility with front-end
      non_filterable_params = params.except(:project_id, :collection_id)
      render json_api: SubjectSerializer.page(non_filterable_params, *selector.queued_subjects)
    else
      super
    end
  end

  private

  def check_subject_limit
    if api_user.above_subject_limit?
      current, max = api_user.subject_limits
      raise Api::LimitExceeded, "User has uploaded #{current} subjects of #{max} maximum"
    end
  end

  def workflow
    @workflow ||= Workflow.where(id: params[:workflow_id]).first
  end

  def build_resource_for_create(create_params)
    locations = create_params.delete(:locations)
    subject = super(create_params) do |object, linked|
      object[:uploader] = api_user.user
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
    (locations || []).each.with_index do |loc, i|
      location_params = { content_type: loc, metadata: { index: i } }
      if api_user.is_admin?
        location_params.merge!(allow_any_content_type: true)
      end
      subject.locations.build(location_params)
    end
    subject
  end

  def context
    case action_name
    when "create", "update"
      { url_format: :put }
    else
      { url_format: :get }
    end
  end

  def selector
    @selector ||= SubjectSelector.new(api_user,
                                      workflow,
                                      params,
                                      controlled_resources)
  end
end
