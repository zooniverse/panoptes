class Api::V1::SubjectsController < Api::ApiController
  include JsonApiController::PunditPolicy

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

  # special end point to liaise with the selector to
  # collate groups of selected subjects
  # order of operations will be
  def grouped
    # ????
    #  ? should we make more than one group at a time to ensure the
    #    classifier has more than 1 subject to work on at a given time?
    #  A yes!
    #    FEM requires min 3 subjects, else it'll request more in the queue
    #    so we should do our best to return at least 3 to avoid the extra requests
    #    First pass at this will be 1
    #    later on we can add a constant(default 3) multiplier to turn into constant num of groups
    skip_policy_scope

    # do the params validation - TODO: extract to a service object
    required_param_keys = %i[workflow_id num_rows num_columns]
    valid_integer_params = params.permit(*required_param_keys).transform_values do |param_value|
      # ensure each param value is an int
      # how can we offload the schema type validations for GET requests?
      param_value.to_i
    end
    SubjectGroupsSelectionSchema.new.validate!(valid_integer_params)

    # get the total number of subjects to be in the specific group
    required_num_of_subjects = params[:num_rows].to_i * params[:num_columns].to_i
    selector_params = params.dup
    selector_params[:page_size] = required_num_of_subjects
    # run the selector with the desired number of
    subject_selector = Subjects::Selector.new(api_user.user, selector_params)
    selected_subject_ids = subject_selector.get_subject_ids

    # try to find any existing SubjectGroup with the key
    subject_group_key = selected_subject_ids.join('-')
    subject_group = SubjectGroup.find_by(key: subject_group_key)
    unless subject_group
      # create the subject group from the selected ids
      subject_group = SubjectGroups::Create.run!(
        subject_ids: selected_subject_ids,
        uploader_id: subject_selector.workflow.owner.id.to_s,
        project_id: subject_selector.workflow.project_id.to_s
      )
    end
    # get the list of the groups 'placeholder' group_subject ids
    group_subject_ids = [subject_group.group_subject.id]

    selected_subject_scope =
      Subject
      .where(id: group_subject_ids)
      .order(
        "idx(array[#{group_subject_ids.join(',')}], id)"
      )

    selection_context = Subjects::SelectorContext.new(
      subject_selector,
      group_subject_ids
    ).format

    non_filterable_params = params.except(:project_id, :collection_id)
    # serialize the subject group and associated subject data
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
end
