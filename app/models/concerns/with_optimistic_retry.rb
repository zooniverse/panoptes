# http://apidock.com/rails/ActiveRecord/Persistence/reload
module WithOptimisticRetry

  private

  def with_optimistic_retry(retries=nil)
    retries ||= 10
    begin
      yield
    rescue ActiveRecord::StaleObjectError => e
      begin
        # Reload lock_version in particular.
        reload
        retries -= 1
      rescue ActiveRecord::RecordNotFound
        # If the record is gone there is nothing to do.
      else      
        if retries > 0
          retry
        else
          raise e
        end
      end
    end
  end
end
