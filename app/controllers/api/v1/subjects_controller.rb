class Api::V1::SubjectsController < Api::ApiController
  include JsonApiController::PunditPolicy
  include Versioned

  require_authentication :update, :create, :destroy, :version, :versions,
    scopes: [:subject]
  resource_actions :show, :index, :create, :update, :deactivate
  schema_type :json_schema

  alias_method :subject, :controlled_resource

  before_action :check_subject_limit, only: :create

  def index
    case params[:sort]
    when 'queued'
      queued
    else
      super
    end
  end

  def queued
    skip_policy_scope

    subject_selector = Subjects::Selector.new(api_user.user, params)
    selected_subject_ids = subject_selector.get_subject_ids

    selected_subject_scope = if selected_subject_ids.empty?
      Subject.none
    else
      Subject
      .active
      .where(id: selected_subject_ids)
      .order(
        "idx(array[#{selected_subject_ids.join(',')}], id)"
      )
    end

    selection_context = Subjects::SelectorContext.new(
      subject_selector,
      selected_subject_ids
    ).format

    non_filterable_params = params.except(:project_id, :collection_id)

    render json_api: SubjectSelectorSerializer.page(
      non_filterable_params,
      selected_subject_scope,
      selection_context
    )
  end

  def create
    raise ApiErrors::FeatureDisabled unless Panoptes.flipper[:subject_uploading].enabled?
    super do |subject|
      user = subject.uploader
      user.increment_subjects_count_cache
    end
  end

  def destroy
    super

    begin
      # use the memoized non-destroyed resource ids to setup a worker
      controlled_resources.each do |subject|
        SubjectRemovalWorker.perform_async(subject.id)
      end
    rescue Timeout::Error => e
      Honeybadger.notify(e)
    end
  end

  private

  def check_subject_limit
    if api_user.above_subject_limit?
      current, max = api_user.subject_limits
      raise Api::LimitExceeded, "User has uploaded #{current} subjects of #{max} maximum"
    end
  end

  def build_resource_for_create(create_params)
    locations = create_params.delete(:locations)
    subject = super(create_params) do |object, linked|
      object[:uploader] = api_user.user
    end
    add_locations(locations, subject)
    subject
  end

  def build_update_hash(update_params, resource)
    if locations = update_params.delete(:locations)
      add_locations(locations, resource)
    end

    update_params
  end

  def add_locations(locations, subject)
    if locations.blank?
      nil
    else
      subject.locations.build(Subject.location_attributes_from_params(locations))
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
end
