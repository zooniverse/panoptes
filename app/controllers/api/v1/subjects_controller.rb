class Api::V1::SubjectsController < Api::ApiController
  include Versioned

  require_authentication :update, :create, :destroy, :version, :versions,
    scopes: [:subject]
  resource_actions :default
  schema_type :json_schema

  alias_method :subject, :controlled_resource

  before_action :check_subject_limit, only: :create

  def index
    case params[:sort]
    when 'queued'
      non_filterable_params = params.except(:project_id, :collection_id)
      render json_api: SubjectSerializer.page(non_filterable_params, *selector.get_subjects)
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
    subject
  end

  def build_update_hash(update_params, id)
    locations = update_params.delete(:locations)
    subject = Subject.find(id)
    subject.locations = add_locations(locations, subject)
    subject.save!
    super(update_params, id)
  end

  def add_locations(locations, subject)
    (locations || []).map.with_index do |loc, i|
      location_params = case loc
                        when String
                          { content_type: loc }
                        when Hash
                          { content_type: loc.keys.first, external_link: true, src: loc.values.first }
                        end
      location_params.merge!(metadata: { index: i })
      location_params.merge!(allow_any_content_type: true) if api_user.is_admin?
      subject.locations.build(location_params)
    end
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
    @selector ||= Subjects::Selector.new(api_user.user,
      workflow,
      params,
      controlled_resources)
  end
end
