# frozen_string_literal: true

class SubjectSetCompletedMailerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(project_id)
    return unless project = Project.find(project_id)

    SubjectSetCompletedMailer.notify_project_team(project).deliver
  end
end
