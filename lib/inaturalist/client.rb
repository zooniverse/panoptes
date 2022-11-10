# frozen_string_literal: true

module Inaturalist
  class Client
    attr_reader :url, :request_url, :headers, :default_params

    def initialize
      @url = 'https://api.inaturalist.org/v1/observations'
      @request_url = nil
      @headers = { 'User-Agent' => 'zooniverse-import' }
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
        f.adapter Faraday.default_adapter
      end

      begin
        response = conn.get
        @request_url = response.env.url.to_s
        conn.get.body
      rescue Faraday::ClientError => e
        raise e
      end
    end
  end
end
