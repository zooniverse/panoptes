class CountWorker
  include Sidekiq::Worker

  def perform(base_class, options)
    options.symbolize_keys!
    options[:source_object_class_name] = base_class.constantize
    counter_class = options[:counter].constantize
    counter = counter_class.new(nil, options)
    counter.save!
  end

  def self.enqueue(delay, base_class, options)
    perform_in(delay, base_class, options)
  end
end
