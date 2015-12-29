module Panoptes
  def self.cellect_on
    @cellect_on ||= (ENV["CELLECT_ON"] || false)
  end

  def self.cellect_min_pool_size
    @cellect_min_pool_size ||= (ENV["CELLECT_MIN_POOL_SIZE"] || 10000).to_i
  end
end
