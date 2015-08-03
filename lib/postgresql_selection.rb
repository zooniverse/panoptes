class PostgresqlSelection
  attr_reader :workflow, :user, :opts

  def initialize(workflow, user=nil)
    @workflow, @user = workflow, user
  end

  def select(options={})
    @opts = options
    results = case selection_strategy
    when :in_order
      select_results_in_order
    else
      select_results_randomly
    end
    results.take(limit)
  end

  private

  def available
    return @available if @available
    query = SetMemberSubject.available(workflow, user)
    @available = case
                 when workflow.grouped
                   query.where(subject_set_id: opts[:subject_set_id])
                 when workflow.prioritized
                   query.order(priority: opts.fetch(:order, :desc))
                 when workflow.grouped && workflow.prioritized
                   raise NotImplementedError
                 else
                   query
                 end
  end

  def available_count
    available.except(:select).count
  end

  def sample(query=available)
    query.where('"set_member_subjects"."random" BETWEEN random() AND random()')
  end

  def limit
    opts.fetch(:limit, 20).to_i
  end

  def selection_strategy
    if workflow.prioritized
      :in_order
    else
      :other
    end
  end

  def select_results_randomly
    results = []
    enough_available = limit < available_count
    if enough_available
      until results.length >= limit do
        results = results | sample.limit(limit).pluck(:id)
      end
    else
      results = available.pluck(:id).shuffle
    end
    results
  end

  def select_results_in_order
    available.limit(limit).pluck(:id)
  end
end
