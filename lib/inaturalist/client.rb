# frozen_string_literal: true

module Inaturalist
  class Client
    attr_reader :url, :request_url, :headers, :default_params

    # iNat API v2 uses RISON to specify desired fields in response.
    # This JSON compiles to the string below
    # {
    #   "id": true,
    #   "observed_on": true,
    #   "time_observed_at": true,
    #   "quality_grade": true,
    #   "num_identification_agreements": true,
    #   "num_identification_disagreements": true,
    #   "location": true,
    #   "geoprivacy": true,
    #   "scientific_name": true,
    #   "license_code": true,
    #   "taxon": {
    #     "scientific_name": true
    #   },
    #   "photos": {
    #     "url": true
    #   }
    # }

    RISON_FIELDS = '(id:!t,observed_on:!t,time_observed_at:!t,quality_grade:!t,num_identification_agreements:!t,num_identification_disagreements:!t,location:!t,geoprivacy:!t,scientific_name:!t,license_code:!t,taxon:(name:!t),photos:(url:!t))'

    def initialize
      @url = 'https://api.inaturalist.org/v2/observations'
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
      request_params['fields'] = RISON_FIELDS
      conn = Faraday.new(
        url: @url,
        headers: @headers,
        params: request_params
      ) do |f|
        f.request :url_encoded
        f.request :retry
        f.response :raise_error
        f.adapter :net_http_persistent
        # f.adapter Faraday.default_adapter
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
