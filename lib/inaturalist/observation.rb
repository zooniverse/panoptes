# frozen_string_literal: true

module Inaturalist
  class Observation
    require 'mini_mime'

    def initialize(obs)
      @obs = obs
    end

    def external_id
      @obs['id']
    end

    def metadata
      @metadata ||= extract_metadata(@obs)
    end

    def extract_metadata(obs)
      metadata = {}
      metadata['id'] = obs['id']
      metadata['change'] = 'No changes were made to this image.'
      metadata['observed_on'] = obs['observed_on']
      metadata['updated_at'] = obs['updated_at']
      metadata['time_observed_at'] = obs['time_observed_at']
      metadata['quality_grade'] = obs['quality_grade']
      metadata['num_identification_agreements'] = obs['num_identification_agreements']
      metadata['num_identification_disagreements'] = obs['num_identification_disagreements']
      metadata['location'] = obs['location']
      metadata['geoprivacy'] = obs['geoprivacy']
      metadata['scientific_name'] = obs['taxon']['name']
      metadata
    end

    def locations
      @locations ||= extract_locations(@obs)
    end

    def extract_locations(obs)
      locations = []
      obs['photos'].each do |p|
        url = p['url'].sub('square', 'large')
        mimetype = mime_type_from_file_extension(url)
        locations << { mimetype => url }
      end
      locations
    end

    def all_rights_reserved?
      @obs['license_code'].nil?
    end

    def mime_type_from_file_extension(url)
      MiniMime.lookup_by_filename(url).content_type
    rescue NoMethodError
      'invalid-filetype'
    end
  end
end
