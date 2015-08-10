# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :subject_queue do

  desc "empty all subject queues"
  task empty_all_queues: :environment do
    EmptySubjectQueueWorker.new.perform
  end

  desc "Empty all workflow subject queues"
  task :empty_all_workflow_queues, [:workflow_id ] => [:environment] do |t, args|
    EmptySubjectQueueWorker.new.perform(args[:workflow_id])
  end
end
