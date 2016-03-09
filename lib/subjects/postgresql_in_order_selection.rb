module Subjects
  class PostgresqlInOrderSelection
    attr_reader :available, :limit

    def initialize(available, limit)
      @available = available
      @limit = limit
    end

    def select
      available.order(priority: :asc).limit(limit).pluck(:id)
    end
  end
end
