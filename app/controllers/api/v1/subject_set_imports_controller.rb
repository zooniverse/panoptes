class Api::V1::SubjectSetImportsController < Api::ApiController
  include JsonApiController::PunditPolicy

  require_authentication :all, scopes: [:project]

  resource_actions :index, :show, :create

  schema_type :json_schema

  def create
    operation = SubjectSetImports::CountManifestRows.with(api_user: api_user)
    # add the count of data rows to store on the SubjectSetImport resource
    # as this count is used for progress reporting while the import runs
    create_params['manifest_count'] = operation.run!(source_url: create_params[:source_url])

    super do |subject_set_import|
      SubjectSetImportWorker.perform_async(subject_set_import.id, create_params['manifest_count'])
    end
  end

  def build_resource_for_create(create_params)
    super do |body_params, link_params|
      body_params[:user_id] = api_user.id
    end
  end
end
