module FilterByMetadata
  extend ActiveSupport::Concern

  included do
    before_action :filter_by_metadata, only: :index
  end

  def filter_by_metadata
    meta_params = params.keys.select { |k| k.to_s.match(/^metadata\..+$/) }

    meta_params.each do |meta_key|
      _, key = meta_key.to_s.split(".")
      value = params.delete(meta_key)
      @controlled_resources = controlled_resources
      .where("\"#{resource_sym}\".\"metadata\" @> ? ", { key => value }.to_json)
    end
  end
end
