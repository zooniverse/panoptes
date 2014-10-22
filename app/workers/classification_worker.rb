class ClassificationWorker
  include Sidekiq::Worker

  def self.perform(id, action)
    classification = ClassificationLifecycle.new(Classification.find(id))
    case action
    when :update
      classification.transact! do
        update_seen_subjects
        dequeue_subject
        publish_to_kafka
      end
    when :create
      classification.transact! do
        update_seen_subjects
        dequeue_subject
        create_project_preference
        publish_to_kafka
      end
    end
  end
end
