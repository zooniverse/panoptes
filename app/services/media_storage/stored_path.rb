# frozen_string_literal: true

module MediaStorage
  module StoredPath
    # Construct the media access URL
    # and ensure we remove the old aws s3 domain prefix in the stored paths
    # but leave intact any non old s3 URL, i.e. new azure ones
    def self.media_url(url, stored_path)
      uri = URI("https://#{stored_path}")
      # if the parse succeeds, we know we have a valid domain prefix,
      # i.e. it is an old s3 stored path - hence, we need to rewrite the url
      PublicSuffix.parse(uri.host)

      uri_path = path_without_env_prefix(uri.path)
      File.join(url, uri_path)
    rescue PublicSuffix::DomainNotAllowed
      # failure here indicates we do not have
      # a valid domain prefix in the stored path
      # e.g. /user_avatar/1e5fc9b5-86f1-4df3-986f-549f02f969a5.jpeg
      # so we do not need to rewrite the URL
      File.join(url, stored_path)
    end

    def self.media_path(stored_path)
      uri = URI("https://#{stored_path}")
      # if the parse succeeds, we know we have a valid domain prefix,
      # i.e. it is an old s3 stored path - hence, we need to extract just the azure path
      PublicSuffix.parse(uri.host)
      path_without_env_prefix(uri.path)
    rescue PublicSuffix::DomainNotAllowed
      # failure here indicates we do not have a valid domain prefix and dont need to rewrite
      # return path as is
      stored_path
    end

    private

    def path_without_env_prefix(uri_path)
      # remove env prefix if present
      env_prefix = '/' + Rails.env
      uri_path.sub(env_prefix, '') if uri_path.start_with? env_prefix
    end
  end
end
