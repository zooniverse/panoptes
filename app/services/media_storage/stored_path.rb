# frozen_string_literal: true

module MediaStorage
  module StoredPath
    # Construct the media access URL
    # and ensure we remove the old aws s3 domain prefix in the stored paths
    # but leave intact any non old s3 URL, i.e. new azure ones
    def self.media_url(url, stored_path)
      uri = URI("https://#{stored_path}")
      PublicSuffix.parse(uri.host)
      # we have a valid domain prefix here so remove it
      # to allow us to construct the URL correctly
      env_prefix = '/' + Rails.env
      uri.path.slice! env_prefix if uri.path.start_with? env_prefix # remove env prefix if present

      File.join(url, uri.path)
    rescue PublicSuffix::DomainNotAllowed
      # failure here indicates we do not have
      # a valid domain prefix in the stored path
      # e.g. /user_avatar/1e5fc9b5-86f1-4df3-986f-549f02f969a5.jpeg
      # so we do not need to rewrite the URL
      File.join(url, stored_path)
    end
  end
end
