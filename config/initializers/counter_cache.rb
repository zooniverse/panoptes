Counter::Cache.configure do |c|
  c.default_worker_adapter = CountWorker
  c.recalculation_delay    = 2.hours
  c.redis_pool             = RedisConfig.counter_pool
end
