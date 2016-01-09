module Panoptes
  def self.lifecycled_live_window
    @lifecycled_live_window ||= (ENV["LIVE_WINDOW"] || 15)
  end
end
