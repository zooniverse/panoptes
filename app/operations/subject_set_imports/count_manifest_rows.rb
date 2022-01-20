# frozen_string_literal: true

module SubjectSetImports
  class CountManifestRows < Operation
    class LimitExceeded < StandardError; end
    class ManifestError < StandardError; end
    string :source_url
    integer :manifest_count, default: -> {
      count_manifest_data_rows
    }
    integer :manifest_row_count_limit, default: -> {
      ENV.fetch('SUBJECT_SET_IMPORT_MANIFEST_ROW_LIMIT', 10000).to_i
    }

    attr_reader :manifest

    def execute
      return manifest_count if user_is_admin || manifest_is_under_limit

      # raise if the incoming manifest is over the allowed limit
      raise(
        LimitExceeded,
        "Manifest row count (#{manifest_count}) exceeds the limit (#{manifest_row_count_limit}) and can not be imported"
      )
    end

    private

    def user_is_admin
      api_user.is_admin?
    end

    def manifest_is_under_limit
      manifest_count <= manifest_row_count_limit
    end

    def count_manifest_data_rows
      UrlDownloader.stream(source_url) do |io|
        csv_import = SubjectSetImport::CsvImport.new(manifest)
        csv_import.count
      end
    rescue UrlDownloader::Failed => e
      raise ManifestError, "Failed to download manifest: #{source_url}"
    end
  end
end
