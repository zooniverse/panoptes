module CellectClient
  ConnectionError = Class.new(StandardError)

  MAX_TRIES = 1
  TIMEOUT = 0.03
  
  def self.add_seen(session, workflow_id, user_id, subject_id)
    RequestToHost.new(session, workflow_id)
      .request(:add_seen, subject_id: subject_id, user_id: user_id)
  end

  def self.load_user(session, workflow_id, user_id)
    RequestToHost.new(session, workflow_id, retries: 3)
      .request(:load_user, user_id: user_id)
  end

  def self.reload_workflow(workflow_id)
    RequestToAll.new(workflow_id, timeout: 30).request(:reload_workflow)
  end

  def self.remove_subject(subject_id, workflow_id, group_id)
    RequestToAll.new(workflow_id)
      .request(:remove_subject, subject_id, group_id: group_id)
  end

  def self.get_subjects(session, workflow_id, user_id, group_id, limit)
    RequestToHost.new(session, workflow_id)
      .request(:get_subjects, group_id: group_id, user_id: user_id, limit: limit)
  end

  singleton_class.class_eval do
    include ::NewRelic::Agent::MethodTracer

    %i(add_seen load_user remove_subject get_subjects).each do |client_method|
      add_method_tracer client_method, "cellect/#{client_method}"
    end
  end

  class Request
    attr_reader :workflow_id, :retries, :timeout
    
    def initialize(workflow_id, retries: MAX_TRIES, timeout: TIMEOUT)
      @workflow_id = workflow_id
      @retries = retries
      @timeout = timeout
    end

    def request(action, *params)
      tries ||= retries
      Timeout.timeout(timeout) { Cellect::Client.connection.send(action, *params) }
    rescue StandardError => e
      Thread.pass
      raise ConnectionError, "Cellect is unavailable" if tries <= 0
      tries -= 1
      yield if block_given?
      retry
    end
  end

  class RequestToAll < Request
    def request(action, *params)
      params = nil if params.blank?
      case params
      when NilClass
        params = [workflow_id]
      when Hash
        params[:workflow_id] = workflow_id
      when Array
        params.last[:workflow_id] = workflow_id if params.last.is_a? Hash
      end
      super action, *params
    end
  end

  class RequestToHost < Request
    def initialize(session, workflow_id, retries: MAX_TRIES, timeout: TIMEOUT)
      @session = session
      super workflow_id, retries: retries, timeout: timeout
    end

    def request(action, params={})
      params[:host] = host
      params[:workflow_id] = workflow_id
      super(action, params) { params[:host] = reset_host }
    end

    def host
      @host ||= if (h = @session[workflow_id]) && Cellect::Client.host_exists?(h)
                  h
                else
                  choose_host
                end
    end

    def reset_host
      @host = choose_host
    end

    def choose_host
      @session[workflow_id] = Cellect::Client.choose_host
    end
  end
end
