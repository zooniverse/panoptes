module Subjects
  class PostgresqlRandomSelection
    attr_reader :available, :limit

    def initialize(available, limit)
      @available = available
      @limit = limit
    end

    def select
      enough_available = limit < available_count
      if enough_available
        ids = sample.pluck(:id).sample(limit)
        if reassign_random?
          RandomOrderShuffleWorker.perform_async(ids)
        end
        ids
      else
        available.pluck(:id).shuffle
      end
    end

    private

    def available_count
      @available_count ||= available.except(:select).count
    end

    def sample(query=available)
      direction = [:asc, :desc].sample
      query.order(random: direction).limit(focus_set_window_size)
    end

    def focus_set_window_size
      @focus_set_window_size ||=
        [
          (available_count * 0.5).ceil,
          Panoptes::SubjectSelection.focus_set_window_size
        ].min
    end

    def reassign_random?
      rand <= Panoptes::SubjectSelection.index_rebuild_rate
    end
  end
end
