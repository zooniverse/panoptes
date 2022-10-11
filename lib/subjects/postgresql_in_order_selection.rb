module Subjects
  class PostgresqlInOrderSelection
    attr_reader :available, :limit

    def initialize(available, limit)
      @available = available
      @limit = limit
    end

    # ensure the order does not run on the available query
    # use a CTE with the available subquery
    # to resolve the ordering to be applied to the joined result set
    # otherwise it attemps to sort the whole available query scope which can be large
    def select
      SetMemberSubject
        .with(available_ids: available)
        .joins('INNER JOIN available_ids ON available_ids.id = set_member_subjects.id')
        .order(priority: :asc)
        .limit(limit)
        .pluck(:subject_id)
    end
  end
end
