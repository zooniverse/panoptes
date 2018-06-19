module Subjects
  class PostgresqlInOrderSelection
    attr_reader :available, :limit

    def initialize(available, limit)
      @available = available
      @limit = limit
    end

    # ensure the order runs outside the subselect here
    # otherwise it attemps to sort the whole available complex joinsed scope
    def select
      SetMemberSubject
      .where(id: available)
      .order(priority: :asc)
      .limit(limit)
      .pluck(:id)
    end
  end
end
