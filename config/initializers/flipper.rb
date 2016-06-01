module Panoptes
  def self.flipper
    @flipper ||= Flipper.new(Flipper::Adapters::ActiveRecord.new)
  end
end
