class PostgresqlSelection
  attr_reader :workflow, :user
  
  def initialize(workflow, user=nil)
    @workflow, @user = workflow, user
  end

  def select(opts={})
    limit = opts.fetch(:limit, 20).to_i
    selection_statement = case
                          when workflow.grouped && workflow.prioritized
                            prioritized_grouped(opts[:subject_set_id])
                          when workflow.grouped
                            grouped(opts[:subject_set_id])
                          when workflow.prioritized
                            prioritized
                          else
                            random
                          end
    
    results = []
    enough_available = false
    first_pass = true
    until results.length >= limit do
      if !enough_available && first_pass
        if limit < available.except(:select).count
          enough_available = true
        else
          results = available.all.shuffle
          break 
        end
      end


      results = results | selection_statement.limit(limit - results.length)
      first_pass = false
    end
    return results.take(limit)
  end

  private
  
  def grouped(group_id=nil)
    SetMemberSubject.with.recursive(sample: sample(available.where(subject_set_id: group_id)))
      .select('"sample"."subject_id"')
      .from("sample")
  end

  def random
    SetMemberSubject.with.recursive(sample: sample)
      .select('"sample"."subject_id"')
      .from("sample")
  end

  def prioritized(limit)
    raise NotImplementedError
  end

  def prioritized_grouped(limit, group_id=nil)
    raise NotImplementedError
  end

  def available
    SetMemberSubject.available(workflow, user)
  end

  def sample(available=available)
    sampler = available.where('"set_member_subjects"."random" BETWEEN random() AND random()')
    "#{sampler.to_sql} UNION #{sampler.to_sql}"
  end
end
