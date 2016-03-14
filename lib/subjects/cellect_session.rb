require 'cellect/client'

module Subjects
  class CellectSession
    NilWorkflowError = Class.new(StandardError)
    NoHostError = Class.new(StandardError)

    attr_reader :user_id, :workflow_id

    def initialize(user_id, workflow_id)
      @user_id = user_id || "unauth"
      unless @workflow_id = workflow_id
        raise NilWorkflowError.new("Nil workflow passed to cellect session")
      end
    end

    def host(ttl=ttl_secs)
      host = Sidekiq.redis do |redis_conn|
        redis_conn.get(user_workflow_key)
      end
      if host && Cellect::Client.host_exists?(host)
        host
      else
        reset_host(ttl)
      end
    end

    def reset_host(ttl=ttl_secs)
      if host = cellect_host
        Sidekiq.redis do |redis_conn|
          redis_conn.setex(user_workflow_key, ttl, host)
        end
        host
      else
        raise NoHostError.new("No cellect host available")
      end
    end

    private

    def user_workflow_key
      "pcs:#{user_id}:#{workflow_id}"
    end

    def cellect_host
      Cellect::Client.choose_host
    end

    def ttl_secs
      3600
    end
  end
end
