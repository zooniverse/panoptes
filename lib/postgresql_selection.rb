class PostgresqlSelection
  attr_reader :workflow, :user, :opts
  
  def initialize(workflow, user=nil)
    @workflow, @user = workflow, user
  end

  def select(options={})
    @opts = options
    limit = opts.fetch(:limit, 20).to_i
    
    results = []
    enough_available = false
    first_pass = true
    until results.length >= limit do
      if !enough_available && !first_pass
        if limit < available_count 
          enough_available = true
        else
          results = available.all.shuffle
          break 
        end
      end
      
      results = results | selection_statement.limit(limit - results.length).map(&:subject_id)
      first_pass = false
    end
    return results.take(limit)
  end

  private
  
  def selection_statement
    @selection ||= case
                   when workflow.grouped && workflow.prioritized
                     prioritized_grouped(opts[:subject_set_id])
                   when workflow.grouped
                     grouped(opts[:subject_set_id])
                   when workflow.prioritized
                     prioritized
                   else
                     random
                   end
  end
  
  def available
    return @available if @available
    query = SetMemberSubject.available(workflow, user)
    @available = case
                 when workflow.grouped
                   query.where(subject_set_id: opts[:subject_set_id])
                 else
                   query
                 end
  end

  def available_count
    available.except(:select).count
  end

  def grouped(group_id=nil)
    SetMemberSubject.with.recursive(sample: sample)
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
  
  def sample
    sampler = available.where('"set_member_subjects"."random" BETWEEN random() AND random()')
    "#{sampler.to_sql} UNION #{sampler.to_sql}"
  end
end
