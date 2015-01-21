class Api::V1::SubjectsController < Api::ApiController
  include JsonApiController
  include Versioned

  doorkeeper_for :update, :create, :destroy, :version, :versions,
                 scopes: [:subject]
  resource_actions :show, :create, :update, :destroy
  schema_type :json_schema
  
  alias_method :subject, :controlled_resource

  def index
    subjects = selector.create_response
    if stale?(last_modified: subjects.maximum(:updated_at))
      render json_api: SubjectSerializer.page(params, subjects)
    end
  end

  private

  def create_response(subject)
    serializer.resource({}, resource_scope(subject), post_urls: true)
  end

  def update_response(subject)
    serializer.resource({}, resource_scope(subject), post_urls: true)
  end

  def build_resource_for_create(create_params)
    create_params[:links][:owner] = owner || api_user.user
    create_params[:locations] = add_subject_path(create_params[:locations],
                                                 create_params[:links][:project])
    subject = super(create_params)
    subject
  end

  def build_resource_for_update(update_params)
    if update_params.has_key? :locations
      update_params[:locations] = add_subject_path(update_params[:locations],
                                                   controlled_resource.project.id)
    end
    super(update_params)
  end

  def selector
    @selector ||= SubjectSelector.new(api_user,
                                      params,
                                      visible_scope,
                                      cellect_host(params[:workflow_id]))
  end
  
  def add_subject_path(locations, project_id)
    locations.map.with_index do |mime, idx|
      mime.split(',').reduce({}) do |location, mime|
        location[mime] = subject_path(idx, mime, project_id)
        location
      end
    end
  end

  def subject_path(location, mime, project_id)
    extension = MIME::Types[mime].first.extensions.first
    "#{::Panoptes.bucket_path}/#{project_id}/#{location}/#{SecureRandom.uuid}.#{extension}"
  end
end
