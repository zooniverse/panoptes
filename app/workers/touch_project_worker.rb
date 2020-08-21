# frozen_string_literal: true

class TouchProjectWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(project_id)
    Project.find(project_id).touch
  end
end
