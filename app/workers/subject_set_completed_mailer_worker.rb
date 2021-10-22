# frozen_string_literal: true

class SubjectSetCompletedMailerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(subject_set_id)
    subject_set = SubjectSet.find(subject_set_id)

    project = subject_set.project
    SubjectSetCompletedMailer.notify_project_team(project, subject_set).deliver
  end
end
