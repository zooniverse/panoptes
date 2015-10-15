namespace :subjects do
  desc "Import subjects from a CSV file"
  task :import, [:project_id, :user_id, :subject_set_id, :url] => [:environment] do |t, args|
    SubjectImportWorker.perform_async(args[:project_id], args[:user_id], args[:subject_set_id], args[:url])
  end
end
