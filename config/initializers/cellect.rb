module Panoptes
  def self.cellect_feature_name
    "cellect"
  end

  def self.cellect_feature
    @cellect_feature ||=
      if Flipper::Adapters::ActiveRecord::Feature.where(key: cellect_feature_name).exists?
        Panoptes.flipper[cellect_feature_name]
      end
  end

  def self.cellect_on
    @cellect_on ||=
      if cellect_feature
        cellect_feature.try(:enabled?)
      else
        ENV["CELLECT_ON"] || false
      end
  end

  def self.cellect_min_pool_size
    @cellect_min_pool_size ||= (ENV["CELLECT_MIN_POOL_SIZE"] || 10000).to_i
  end

  def self.use_cellect?(workflow)
    cellect_on && workflow.using_cellect?
  end
end

cellect_timeout = ENV["CELLECT_HTTP_TIMEOUT"].to_f
if cellect_timeout != 0.0
  Cellect::Client::Connection.timeout = cellect_timeout
end
