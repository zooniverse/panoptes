# frozen_string_literal: true

module Inaturalist
  class ApiInterface
    require 'faraday'
    require 'faraday_middleware'
    require 'json'

    # Set maximum imported subjects, or no limit with -1
    attr_reader :taxon_id, :total_results, :observation_cache, :params

    def initialize(taxon_id:, updated_since: nil, max_observations: -1)
      @taxon_id = taxon_id
      @max_observations = max_observations
      @observation_cache = []
      @id_above = 0
      @params = { taxon_id: @taxon_id }
      @params[:updated_since] = updated_since unless updated_since.nil?
      @done = false
      @total_results = nil
    end

    def observations
      Enumerator.new do |yielder|
        loop do
          results = fetch_next_page
          raise StopIteration if @done

          results.each do |obs|
            yielder.yield Observation.new(obs)
          end
        end
      end
    end

    def fetch_next_page
      page_params = @params.merge(id_above: @id_above)
      response = client.get(page_params)
      @total_results ||= response['total_results']
      results = response['results']
      # Stop if a) there are no more results
      #         b) the total number of desired subjects is hit
      #         c) the ID of the last seen observation is the same as the last result's id
      @done = true if results.empty? || max_cache_hit? || @id_above == results.last['id']
      return if @done

      @observation_cache += results
      @id_above = results.last['id']
      @params['id_above'] = @id_above
      results
    end

    def max_cache_hit?
      # Short circuit to turn off limit
      return false if @max_observations == -1
      @observation_cache.size >= @max_observations
    end

    def client
      @client ||= Client.new
    end
  end
end
