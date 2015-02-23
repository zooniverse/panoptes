class HoneybadgerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(notice)
    Honeybadger.sender.send_to_honeybadger(notice)
  end
end
