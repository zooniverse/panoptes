module Panoptes
  def self.cellect_min_pool_size
    @cellect_min_pool_size ||= (ENV["CELLECT_MIN_POOL_SIZE"] || 10000).to_i
  end
end

cellect_timeout = ENV["CELLECT_HTTP_TIMEOUT"].to_f
if cellect_timeout != 0.0
  Cellect::Client::Connection.timeout = cellect_timeout
end
