require "flipper/instrumentation/log_subscriber"
require 'flipper/adapters/active_record'

module Panoptes
  def self.flipper
    return @flipper if @flipper
    adapter = Flipper::Adapters::ActiveRecord.new
    @flipper = Flipper.new(adapter, instrumenter: ActiveSupport::Notifications)
  end
end
