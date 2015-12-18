module Subjects
  class CellectSession
    NilWorkflowError = Class.new(StandardError)
    attr_reader :user_id, :workflow_id

    def initialize(user_id, workflow_id)
      @user_id = user_id || "unauth"
      unless @workflow_id = workflow_id
        raise NilWorkflowError.new("Nil workflow passed to cellect session")
      end
    end

    def host(ttl_secs=3600)
      Sidekiq.redis do |conn|
        if host = conn.get(user_workflow_key)
          host
        else
          host = choose_new_host
          conn.setex(user_workflow_key, ttl_secs, host)
          host
        end
      end
    end

    private

    def user_workflow_key
      "pcs:#{user_id}:#{workflow_id}"
    end

    def choose_new_host
      Cellect::Client.choose_host
    end
  end
end
