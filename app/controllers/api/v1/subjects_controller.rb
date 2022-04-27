class Api::V1::SubjectsController < Api::ApiController
  include JsonApiController::PunditPolicy

  RESERVED_METADATA_KEYS = ['#priority'].freeze

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

  # special selection end point for known subject ids
  def selection
    # temporary feature flag in case we need a prod 'kill' switch for this feature
    raise ApiErrors::FeatureDisabled unless Panoptes.flipper[:subject_selection_by_ids].enabled?

    skip_policy_scope

    # setup the selector params from user input, note validation occurs in the operation class
    selector_param_keys = %i[workflow_id ids http_cache admin]
    selector_params = params.permit(*selector_param_keys)
    worfklow_id = selector_params.delete(:workflow_id)

    selected_subject_ids = Subjects::SelectionByIds.run!(
      ids: selector_params.delete(:ids),
      workflow_id: worfklow_id
    )

    selected_subject_scope =
      if selected_subject_ids.empty?
        Subject.none
      else
        Subject.active.where(id: selected_subject_ids).order("idx(array[#{selected_subject_ids.join(',')}], id)") # guardrails-disable-line
      end

    # create a special 'fake' selector for the serializer
    subject_selector = OpenStruct.new(
      user: api_user.user,
      workflow: Workflow.find_without_json_attrs(worfklow_id),
      selection_state: :normal # this end point will always be normal or raise
    )

    selection_context = Subjects::SelectorContext.new(
      subject_selector,
      selected_subject_ids
    ).format

    render json_api: SubjectSelectorSerializer.page(
      selector_params,
      selected_subject_scope,
      selection_context
    )
  end

  # special selection end point create SubjectGroups
  def grouped
    # temporary feature flag in case we need a prod 'kill' switch for this feature
    raise ApiErrors::FeatureDisabled unless Panoptes.flipper[:subject_group_selection].enabled?

    skip_policy_scope

    # setup the selector params from user input, note validation occurs in the operation class
    selector_param_keys = %i[workflow_id subject_set_id num_rows num_columns http_cache admin]
    selector_params = params.permit(*selector_param_keys)

    group_selection_result = SubjectGroups::Selection.run!(
      num_rows: selector_params.delete(:num_rows),
      num_columns: selector_params.delete(:num_columns),
      uploader_id: ENV.fetch('SUBJECT_GROUP_UPLOADER_ID'),
      params: selector_params,
      user: api_user
    )
    # get the list of the groups 'placeholder' group_subject ids
    group_subject_ids = group_selection_result.subject_groups.map(&:group_subject_id)

    selected_subject_scope =
      Subject
      .where(id: group_subject_ids)
      .order("idx(array[#{group_subject_ids.join(',')}], id)") # guardrails-disable-line

    selection_context = Subjects::SelectorContext.new(
      group_selection_result.subject_selector,
      group_subject_ids
    ).format

    # serialize the subject_group's group_subject data
    render json_api: SubjectSelectorSerializer.page(
      group_selection_result.subject_selector.params,
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
    downcase_reserved_metadata_keys(create_params)
    locations = create_params.delete(:locations)
    subject = super(create_params) do |object, linked|
      object[:uploader] = api_user.user
    end
    add_locations(locations, subject)
    subject
  end

  def build_update_hash(update_params, resource)
    downcase_reserved_metadata_keys(update_params)
    locations = update_params.delete(:locations)
    new_locations = add_locations(locations, resource)
    subject.save!
    subject.locations = new_locations if new_locations
    super(update_params, resource)
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

  def downcase_reserved_metadata_keys(params)
    return unless params.key?(:metadata)

    params[:metadata].transform_keys! do |key|
      if RESERVED_METADATA_KEYS.include?(key.downcase)
        key.downcase
      else
        key
      end
    end
  end
end
