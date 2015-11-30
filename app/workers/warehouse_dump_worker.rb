require 'csv'

class WarehouseDumpWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence(backfill: true) { daily.hour_of_day(1) }

  def perform(last_occurence, current_occurence)
    from = Time.at(last_occurence)
    till = Time.at(current_occurence)

    Project.find_each do |project|
      Tempfile.create "project-#{project.id}-nightly-export", Rails.root.join("tmp") do |tempfile|
        csv = CSV.new(tempfile)
        dump = ClassificationsDump.new(project,
                                       obfuscate_private_details: false,
                                       date_range: date_range(from, till))
        dump.write_to(csv)
        tempfile.rewind
        Warehouse.store(warehouse_path(project.id, from, till), tempfile.path)
      end
    end
  end

  def date_range(from, till)
    if from && till
      from..till
    else
      raise "Need both start and end timestamp for nightly export"
    end
  end

  def warehouse_path(project_id, from, till)
    "project-#{project_id}/classifications/#{date_string(from, till)}.csv"
  end

  def date_string(from, till)
    "#{from.to_i}_#{till.to_i}"
  end
end
