class Api::V1::SubjectSetImportsController < Api::ApiController
  include JsonApiController::PunditPolicy

  require_authentication :all, scopes: [:project]

  resource_actions :index, :show, :create

  schema_type :json_schema

  def create
    # get a data row count of the incoming manifest
    manifest_count = count_manifest_rows

    # add the count of data rows to store on the SubjectSetImport resource
    # as this count is used for progress reporting while the import runs
    create_params['manifest_count'] = manifest_count

    super do |subject_set_import|
      SubjectSetImportWorker.perform_async(subject_set_import.id)
    end
  end

  def build_resource_for_create(create_params)
    super do |body_params, link_params|
      body_params[:user_id] = api_user.id
    end
  end

  private

  # TODO: extract this to an operation that returns the manifest count
  # and avoid the controller test setup cruft
  # should have done this the first time :(
  def count_manifest_rows
    manifest_count = UrlDownloader.stream(create_params[:source_url]) do |io|
      csv_import = SubjectSetImport::CsvImport.new(io)
      csv_import.count
    end

    manifest_row_count_limit = ENV.fetch('SUBJECT_SET_IMPORT_MANIFEST_ROW_LIMIT', 10000)
    manifest_is_over_limit = manifest_count > manifest_row_count_limit
    user_is_not_admin = !api_user.is_admin?

    if user_is_not_admin && manifest_is_over_limit
      # raise if the incoming manifest is not over the allowed limit
      error_message = "Manifest row count (#{manifest_count}) exceeds the limit (#{manifest_row_count_limit}) and can not be imported"
      raise(Api::ImportManifestLimitExceeded, error_message)
    end

    manifest_count
  end
end
