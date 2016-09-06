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
    when "create"
      lifecycle.create!
    when "update"
      lifecycle.update!
    else
      raise "Invalid Post-Classification Action"
    end
  end
end
