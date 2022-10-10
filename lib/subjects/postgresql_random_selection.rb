module Subjects
  class PostgresqlRandomSelection
    using Refinements::RangeClamping

    attr_reader :available, :limit

    def initialize(available, limit)
      @available = available
      @limit = limit
    end

    def select
      ids = available_scope.pluck(:subject_id).sample(limit)
      if reassign_random?
        RandomOrderShuffleWorker.perform_async(ids)
      end
      ids
    end

    private

    def available_scope
      if limit < available_count
        focus_window_random_sample
      else
        available
      end
    end

    def available_count
      @available_count ||= available.except(:select).count
    end

    # ensure the order does not run on the available query
    # use a CTE with the available subquery
    # to resolve the ordering to be applied to the joined result set
    # otherwise it attemps to sort the whole available query scope which can be large
    def focus_window_random_sample
      SetMemberSubject.with(available_ids: available).joins('INNER JOIN available_ids ON available_ids.id = set_member_subjects.id').order(random: %i[asc desc].sample).limit(focus_set_window_size)
    end

    def focus_set_window_size
      @focus_set_window_size ||=
        [
          limit_window,
          Panoptes::SubjectSelection.focus_set_window_size
        ].min
    end

    def limit_window
      half_available_count = (available_count * 0.5).ceil
      if half_available_count < limit
        limit
      else
        half_available_count
      end
    end

    def reassign_random?
      rand <= Panoptes::SubjectSelection.index_rebuild_rate
    end
  end
end
