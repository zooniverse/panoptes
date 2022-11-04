# frozen_string_literal: true

class InatImportCompletedMailerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(ss_import_id)
    ss_import = SubjectSetImport.find(ss_import_id)
    InatImportCompletedMailer.inat_import_complete(ss_import).deliver
  end
end
