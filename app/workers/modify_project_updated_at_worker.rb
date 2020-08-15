# frozen_string_literal: true

class ModifyProjectUpdatedAtWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform(project_id)
    Project.find(project_id).touch
  end
end
