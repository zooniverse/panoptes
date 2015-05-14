class ClassificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(id, action)
    classification = ClassificationLifecycle.new(Classification.find(id))
    case action
    when "update"
      classification.transact!
    when "create"
      classification.transact! do
        classification.subject_ids.each do |sid|
          ClassificationCountWorker.perform_async(sid, classification.workflow.id)
        end
        create_project_preference
      end
    else
      raise "Invalid Post-Classification Action"
    end
  end
end
