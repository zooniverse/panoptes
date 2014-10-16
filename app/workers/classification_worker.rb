class ClassificationWorker
  include Sidekiq::Worker

  def self.perform(id, action)
    classification = ClassificationLifecycle.new(Classification.find(id))
    case action
    when :update
      classification.on_update
    when :create
      classification.on_create
    end
  end
end
