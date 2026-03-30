# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :organization_projects do
  desc 'Backfill organization_projects from legacy projects.organization_id links'
  task backfill_from_projects: :environment do
    scope = Project.where.not(organization_id: nil)
    total = scope.count
    inserted = 0
    processed = 0

    puts "Backfilling organization_projects from #{total} project rows..."

    scope.find_in_batches(batch_size: 1_000).with_index do |batch, batch_index|
      batch.each do |project|
        processed += 1
        organization_project = OrganizationProject.find_or_initialize_by(
          organization_id: project.organization_id,
          project_id: project.id
        )
        next unless organization_project.new_record?

        organization_project.save!
        inserted += 1
      end
      puts "Processed batch #{batch_index + 1} (#{processed}/#{total})"
    end

    puts "Done. Inserted #{inserted} organization_project rows."
  end

end
