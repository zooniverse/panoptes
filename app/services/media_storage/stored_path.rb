# frozen_string_literal: true

module MediaStorage
  # StoredPath: module used by AzureAdapter for constructing the
  # stored path/url of the media resource in azure
  #
  # Old S3 paths will include the panoptes-uploads domain prefix
  # and the environment in their path, for example:
  # panoptes-uploads.zooniverse.org/staging/subject_location/49f02f969a5.jpeg
  # These URLs need to be rewritten such that domain prefix and env get removed
  # Azure native paths do not need to be rewritten
  module StoredPath
    # Construct path and join to the passed in URL
    def self.media_url(url, stored_path)
      uri = URI("https://#{stored_path}")
      # if the parse succeeds, we know we have a valid domain prefix,
      # i.e. it is an old s3 stored path and we need to rewrite it
      PublicSuffix.parse(uri.host)

      uri_path = path_without_env_prefix(uri.path)
      File.join(url, uri_path)
    rescue PublicSuffix::DomainNotAllowed
      # if parse fails, we do not have a valid domain prefix in the stored path
      # e.g. /user_avatar/1e5fc9b5-86f1-4df3-986f-549f02f969a5.jpeg
      # so we do not need to rewrite the URL
      File.join(url, stored_path)
    end

    def self.media_path(stored_path)
      uri = URI("https://#{stored_path}")
      PublicSuffix.parse(uri.host)
      # S3 path
      path_without_env_prefix(uri.path)
    rescue PublicSuffix::DomainNotAllowed
      # azure path
      stored_path
    end

    private_class_method def self.path_without_env_prefix(uri_path)
      # remove env prefix if present
      env_prefix = '/' + Rails.env
      uri_path.sub(env_prefix, '') if uri_path.start_with? env_prefix
    end
  end
end
