class Api::V1::SubjectsController < Api::ApiController
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
    selector = Subjects::Selector.new(api_user.user, workflow, params)
    non_filterable_params = params.except(:project_id, :collection_id)
    selected_subjects = selector.get_subjects
    render json_api: SubjectSelectorSerializer.page(
      non_filterable_params,
      selected_subjects,
      selector_context(selected_subjects.map(&:id))
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
    super do |subject|
      begin
        SubjectRemovalWorker.perform_async(subject.id)
      rescue Timeout::Error => e
        Honeybadger.notify(e)
      end
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
      subject.locations.build(location_params(locations))
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

  def location_params(locations)
    (locations || []).map.with_index do |loc, i|
      location_params = case loc
                        when String
                          { content_type: Subject.nonstandard_mimetypes[loc] || loc }
                        when Hash
                          {
                            content_type: loc.keys.first,
                            external_link: true,
                            src: loc.values.first
                          }
                        end
      location_params[:metadata] = { index: i }
      location_params[:allow_any_content_type] = true if api_user.is_admin?
      location_params
    end
  end

  def selector_context(selected_subject_ids)
    if Panoptes.flipper[:skip_subject_selection_context].enabled?
      {}
    else
      {
        workflow: workflow,
        user: api_user.user,
        user_seen: user_seen,
        url_format: :get,
        favorite_subject_ids: FavoritesFinder.new(api_user.user, workflow.project, selected_subject_ids).find_favorites,
        retired_subject_ids: SubjectWorkflowRetirements.new(workflow, selected_subject_ids).find_retirees,
        user_has_finished_workflow: api_user.user&.has_finished?(workflow),
        select_context: true
      }.compact
    end
  end

  def user_seen
    if api_user.user
      UserSeenSubject.where(user: api_user.user, workflow: workflow).first
    end
  end
end
