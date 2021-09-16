# frozen_string_literal: true

module CellectClient
  class ConnectionError < StandardError; end
  class ResourceNotFound < StandardError; end
  class ServerError < StandardError; end

  def self.host
    @host ||= ENV.fetch('CELLECT_HOST')
  end

  def self.add_seen(workflow_id, user_id, subject_id)
    path = "/workflows/#{workflow_id}/users/#{user_id}/add_seen"
    params = { subject_id: subject_id }
    Request.new.request(:put, [path, params])
  end

  def self.load_user(workflow_id, user_id)
    path = "/workflows/#{workflow_id}/users/#{user_id}/load"
    Request.new.request(:post, path)
  end

  def self.reload_workflow(workflow_id)
    return unless Panoptes.flipper.enabled? 'cellect'

    path = "/workflows/#{workflow_id}/reload"
    Request.new.request(:post, path)
  end

  def self.remove_subject(subject_id, workflow_id, group_id)
    path = "/workflows/#{workflow_id}/remove"
    params = { subject_id: subject_id, group_id: group_id }
    Request.new.request(:put, [path, params])
  end

  def self.get_subjects(workflow_id, user_id, group_id, limit)
    path = "/workflows/#{workflow_id}"
    params = { user_id: user_id, group_id: group_id, limit: limit }
    Request.new.request(:get, [path, params])
  end

  class Request
    attr_reader :connection

    def initialize(adapter=Faraday.default_adapter, host=CellectClient.host)
      @connection = connect!(adapter, host)
    end

    def request(http_method, params)
      response = connection.send(http_method, *params) do |req|
        req.headers['Accept'] = 'application/json'
        req.headers['Content-Type'] = 'application/json'
        req.options.timeout = 5      # open/read timeout in seconds
        req.options.open_timeout = 2 # connection open timeout in seconds
        yield req if block_given?
      end

      handle_response(response)
    rescue Faraday::TimeoutError,
           Faraday::ConnectionFailed => e
      raise ConnectionError, e.message
    end

    private

    def connect!(adapter, host)
      Faraday.new(host, ssl: { verify: false }) do |faraday|
        faraday.request :json
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter(*adapter)
      end
    end

    def handle_response(response)
      case response.status
      when 404
        raise ResourceNotFound, status: response.status, body: response.body
      when 400..600
        raise ServerError, response.body
      else
        response.body
      end
    end
  end
end
