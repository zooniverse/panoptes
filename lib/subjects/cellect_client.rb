module Subjects
  module CellectClient
    ConnectionError = Class.new(StandardError)

    MAX_TRIES = 1

    def self.add_seen(session, workflow_id, user_id, subject_id)
      RequestToHost.new(session, workflow_id)
        .request(:add_seen, subject_id: subject_id, user_id: user_id)
    end

    def self.load_user(session, workflow_id, user_id)
      RequestToHost.new(session, workflow_id, retries: 3)
        .request(:load_user, user_id: user_id)
    end

    def self.reload_workflow(workflow_id)
      RequestToAll.new(workflow_id).request(:reload_workflow)
    end

    def self.remove_subject(subject_id, workflow_id, group_id)
      RequestToAll.new(workflow_id)
        .request(:remove_subject, subject_id, group_id: group_id)
    end

    def self.get_subjects(session, workflow_id, user_id, group_id, limit)
      RequestToHost.new(session, workflow_id)
        .request(:get_subjects, group_id: group_id, user_id: user_id, limit: limit)
    end

    class Request
      attr_reader :workflow_id, :retries

      def initialize(workflow_id, retries: MAX_TRIES)
        @workflow_id = workflow_id
        @retries = retries
      end

      def request(action, *params)
        tries ||= retries
        Cellect::Client.connection.send(action, *params)
      rescue StandardError => e
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
      def initialize(session, workflow_id, retries: MAX_TRIES)
        @session = session
        super workflow_id, retries: retries
      end

      def request(action, params={})
        params[:host] = host
        params[:workflow_id] = workflow_id
        super(action, params) { params[:host] = reset_host }
      end

      def host
        return @host  if @host
        host = @session[workflow_id]
        @host = if host && Cellect::Client.host_exists?(host)
          host
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
end
