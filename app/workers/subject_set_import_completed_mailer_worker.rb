# frozen_string_literal: true

class SubjectSetImportCompletedMailerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(subject_set_import_id)
    subject_set_import = SubjectSetImport.find(subject_set_import_id)
    project = subject_set_import.subject_set.project

    SubjectSetImportCompletedMailer.notify_project_team(project, subject_set_import).deliver
  end
end
