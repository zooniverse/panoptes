class ClassificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(id, action)
    classification_lifecycle = ClassificationLifecycle.new(Classification.find(id))
    case action
    when "update"
      classification_lifecycle.transact!
    when "create"
      classification_lifecycle.transact! do
        if should_count_towards_retirement?
          classification.subject_ids.each do |sid|
            ClassificationCountWorker.perform_async(sid, classification.workflow.id)
          end
        end
        create_project_preference
      end
    else
      raise "Invalid Post-Classification Action"
    end
  end
end
