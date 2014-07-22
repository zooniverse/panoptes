class Api::V1::ClassificationsController < Api::ApiController
  doorkeeper_for :show, :index, scopes: [:classifications]

  def show
    render json_api: ClassificationSerializer.resource(params)
  end

  def index
    render json_api: ClassificationSerializer.page(params)
  end

  def create
    classification = Classification.new(creation_params)
    classification.user_ip = request_ip
    if user = current_resource_owner
      update_cellect
      classification.user = user
    end
    classification.save!
    json_api_render( 201,
                     ClassificationSerializer.resource(classification),
                     api_classification_url(classification) )

  end

  private

  def update_cellect
    Cellect::Client.connection.add_seen(**cellect_params)
  end

  def classification_params
    params.require(:classification)
  end

  def cellect_params
    classification_params.permit(:workflow_id, :subject_id)
      .merge(user_id: current_resource_owner.id,
             host: cellect_host(params[:workflow_id]))
      .symbolize_keys
  end

  def creation_params
    ensure_json_annotations
    permitted_attrs = [ :project_id,
                        :workflow_id,
                        :set_member_subject_id ]
    classification_params.permit(*permitted_attrs).tap do |while_listed|
      while_listed[:annotations] = params[:classification][:annotations]
    end
  end

  def ensure_json_annotations
    if annotations = classification_params["annotations"]
      begin
        JSON.parse(annotations)
      rescue TypeError
        error_message = "Validation failed: Annotations must be valid serialized JSON"
        raise InvalidJsonAnnotationsError.new(error_message)
      end
    end
  end
end
