module Panoptes
  def self.lifecycled_live_window
    return @lifecycled_live_window if @lifecycled_live_window
    window = ENV["LIVE_WINDOW"].to_i
    @lifecycled_live_window = (window == 0 ? 15 : window)
  end
end
