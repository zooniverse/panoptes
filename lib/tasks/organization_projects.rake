# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :organization_projects do
  desc 'Backfill organization_projects from legacy projects.organization_id links'
  task backfill_from_projects: :environment do
    scope = Project.where.not(organization_id: nil)
    total = scope.count
    before_count = OrganizationProject.count

    puts "Backfilling organization_projects from #{total} project rows..."

    scope.find_in_batches(batch_size: 1_000).with_index do |batch, batch_index|
      now = Time.current
      rows = batch.map do |project|
        {
          organization_id: project.organization_id,
          project_id: project.id,
          created_at: now,
          updated_at: now
        }
      end

      OrganizationProject.insert_all(rows, unique_by: :index_organization_projects_on_organization_id_and_project_id)
      puts "Processed batch #{batch_index + 1}"
    end

    inserted = OrganizationProject.count - before_count
    puts "Done. Inserted #{inserted} organization_project rows."
  end
end
