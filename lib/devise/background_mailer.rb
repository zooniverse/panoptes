# Mailer proxy to send devise emails in the background via sidekiq delay method
# uses the Sidekiq::Extensions::DelayedMailer.jobs queue
module Devise
  class BackgroundMailer

    def self.confirmation_instructions(record, token, opts = {})
      new(:confirmation_instructions, record, token, opts)
    end

    def self.reset_password_instructions(record, token, opts = {})
      new(:reset_password_instructions, record, token, opts)
    end

    def self.unlock_instructions(record, token, opts = {})
      new(:unlock_instructions, record, token, opts)
    end

    def initialize(method, record, token, opts = {})
      @method, @record, @token, @opts = method, record, token, opts
    end

    def deliver
      deliver_later
    end

    def deliver_now
      deliver_later
    end

    def deliver_later
      mailer.deliver_later
    rescue Redis::CannotConnectError, Redis::TimeoutError, Timeout::Error
      mailer.deliver_now
    end

    private

    def mailer
      Devise::Mailer.send(@method, @record, @token, @opts)
    end
  end
end
