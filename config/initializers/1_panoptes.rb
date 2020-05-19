module Panoptes
  def self.lifecycled_live_window
    ENV.fetch('LIVE_WINDOW', 15)
  end

  def self.disable_lifecycle_worker
    Panoptes.flipper[:disable_lifecycle_worker].enabled?
  end

  def self.pg_statement_timeout
    ENV.fetch('PG_STATEMENT_TIMEOUT', 300000)
  end

  def self.max_page_size_limit
    ENV.fetch('PAGE_SIZE_LIMIT', 100)
  end
end
