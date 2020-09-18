# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ingore pg cancelled errors honeybadger', type: :request do
  # https://github.com/rspec/rspec-rails/issues/1596#issuecomment-416991848
  # add in a test controller and wire up a route to test it
  # via this request spec
  class TestController < ::ApplicationController
    def test
      # use the below to reproduce the error
      # ActiveRecord::Base.connection.execute("SET statement_timeout = 1")
      # ActiveRecord::Base.connection.execute("SELECT pg_sleep(2);")
      raise ActiveRecord::StatementInvalid, 'PG::QueryCanceled: ERROR:  canceling statement due to statement timeout\n: SELECT pg_sleep(2);'
    end
  end

  before do
    # add a test route for this
    Rails.application.routes.append do
      get :test, to: 'test#test'
    end
    # API key has to be set to get HB reporting in test backend
    Honeybadger.configure do |config|
      config.api_key = 'project api key'
      config.backend = :test
    end
  end

  after do
    Honeybadger.configure do |config|
      config.api_key = nil
      config.backend = nil
    end
  end

  describe 'handling PG::QueryCanceled statement timeout exceptions' do
    let(:get_request) do
      get '/test'
    rescue ActiveRecord::StatementInvalid
      # swallow this error as we expect it for the test
    end

    # use request spec to test HB config
    # https://docs.honeybadger.io/lib/ruby/getting-started/tests-and-honeybadger.html
    it 'does not report to honeybadger' do
      expect {
        # Important: `Honeybadger.flush` ensures that asynchronous notifications
        # are delivered before the test's remaining expectations are verified.
        Honeybadger.flush
      }.not_to change(Honeybadger::Backend::Test.notifications[:notices], :size)
    end
  end
end
