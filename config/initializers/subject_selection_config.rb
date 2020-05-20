# frozen_string_literal: true

module Panoptes
  module SubjectSelection
    def self.focus_set_window_size
      ENV.fetch('SELECTION_FOCUS_SET_WINDOW_SIZE', 1000)
    end

    def self.index_rebuild_rate
      ENV.fetch('SELECTION_INDEX_REBUILD_RATE', 0.01)
    end
  end
end
