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
    class << self
      ENV_REMOVAL_REGEX = /\A(?:\/?#{Rails.env}\/?)?(.+)\z/.freeze

      def media_path(stored_path)
        rewrite_stored_path(stored_path)
      rescue PublicSuffix::DomainNotAllowed
        # a valid stored path without a TLD prefix
        stored_path
      end

      def media_url(domain_prefix, stored_path)
        begin
          azure_path = rewrite_stored_path(stored_path)
        rescue PublicSuffix::DomainNotAllowed
          azure_path = stored_path
        end
        File.join(domain_prefix, azure_path)
      end

      private

      def rewrite_stored_path(stored_path)
        uri = URI("https://#{stored_path}")

        # throw PublicSuffix::DomainNotAllowed if uri.host parse fails
        # this indicates no valid top level domain (TLD) prefix in the stored path
        # e.g. /user_avatar/1e5fc9b5-86f1-4df3-986f-549f02f969a5.jpeg
        # this means the stored_path is valid and we do not need to rewrite the URL at all
        PublicSuffix.parse(uri.host)

        # remove Rails env prefix if present (remnant path prefix from s3 land)
        uri.path.match(ENV_REMOVAL_REGEX)[1]
      end
    end
  end
end
