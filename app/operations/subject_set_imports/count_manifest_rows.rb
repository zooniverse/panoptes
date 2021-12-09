# frozen_string_literal: true

module SubjectSetImports
  class CountManifestRows < Operation
    class LimitExceeded < ApiErrors::PanoptesApiError; end
    string :source_url
    integer :manifest_count, default: -> {
      UrlDownloader.stream(source_url) do |io|
        csv_import = SubjectSetImport::CsvImport.new(io)
        csv_import.count
      end
    }

    def execute
      return manifest_count if user_is_admin || manifest_is_under_limit

      # raise if the incoming manifest is over the allowed limit
      raise(
        LimitExceeded,
        "Manifest row count (#{manifest_count}) exceeds the limit (#{manifest_row_count_limit}) and can not be imported"
      )
    end

    private

    def manifest_row_count_limit
      ENV.fetch('SUBJECT_SET_IMPORT_MANIFEST_ROW_LIMIT', 10000)
    end

    def user_is_admin
      api_user.is_admin?
    end

    def manifest_is_under_limit
      manifest_count <= manifest_row_count_limit
    end
  end
end
