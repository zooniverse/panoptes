require "flipper/instrumentation/log_subscriber"

module Panoptes
  def self.flipper
    return @flipper if @flipper
    adapter = Flipper::Adapters::ActiveRecord.new
    @flipper = Flipper.new(adapter, instrumenter: ActiveSupport::Notifications)
  end
end
