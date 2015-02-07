class ClassificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high, retry: 3

  def perform(id, action)
    classification = ClassificationLifecycle.new(Classification.find(id))
    case action
    when :update
      classification.transact!
    when :create
      classification.transact! { create_project_preference }
    end
  end
end
