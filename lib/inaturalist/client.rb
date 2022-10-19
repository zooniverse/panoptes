module Inaturalist
  class Client
    attr_reader :url, :headers, :default_params
    def initialize
      @url ||= 'https://api.inaturalist.org/v1/observations'
      @headers = {'User-Agent' => 'zooniverse-testing'}
      @default_params = {
        verifiable: true,
        order: 'asc',
        order_by: 'id',
        per_page: 200
      }
    end

    def get(params)

      request_params = @default_params.merge(params)
      conn = Faraday.new(
        url: @url,
        headers: @headers,
        params: request_params
      ) do |f|
        f.request :url_encoded
        f.request :retry
        f.response :raise_error
        f.response :json
        f.adapter Faraday.default_adapter
      end;

      begin
        conn.get.body
      rescue Faraday::ClientError => e
        raise e
      end
    end

  end
end
