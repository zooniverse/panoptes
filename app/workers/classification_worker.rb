require 'classification_lifecycle'

class ClassificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  attr_reader :classification, :action

  def perform(id, action)
    @classification = Classification.find(id)
    @action = action
    lifecycle_classification
  end

  private

  def lifecycle_classification
    lifecycle = ClassificationLifecycle.new(classification)
    case action
    when "update"
      lifecycle.transact!
    when "create"
      if classification.lifecycled_at.nil?
        lifecycle.transact! do
          if should_count_towards_retirement?
            classification.subject_ids.each do |sid|
              ClassificationCountWorker
              .perform_async(sid, classification.workflow.id)
            end
          end
          process_project_preference
        end
      end
    else
      raise "Invalid Post-Classification Action"
    end
  end
end
