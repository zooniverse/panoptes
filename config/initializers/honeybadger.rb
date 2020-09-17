# frozen_string_literal: true

module IngoredErrorRegexes
  PG_QUERY_TIMEOUT = /^ActiveRecord::StatementInvalid: PG::QueryCanceled: ERROR:  canceling statement due to statement timeout/.freeze
end

Honeybadger.configure do |config|
  # ignore the active record PG statement timeout errors
  config.before_notify do |notice|
    notice.halt! if IngoredErrorRegexes::PG_QUERY_TIMEOUT.match?(notice.error_message)
  end
end
