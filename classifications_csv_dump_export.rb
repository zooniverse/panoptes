# Manual csv classifications dump
# ensure you have a manual secondary database connection specified in config/database.yml
#
# Edit as required for project vs. workflow
#
# run via rails runner from the panoptes dir via
# rails r project_classifications_csv_dump_export.rb

require 'csv'
require 'pry'

# PROJECT_ID = 1
WORKFLOW_ID = 14384

# @resource = Project.find PROJECT_ID
@resource = Workflow.find WORKFLOW_ID

def completed_resource_classifications
  @resource
  .classifications
  .complete
  # .joins(:workflow).where(workflows: {activated_state: "active"})
  # .includes(:user, workflow: [:workflow_contents])
end

def setup_subjects_cache(classifications)
  classification_ids = classifications.map(&:id).join(",")
  sql = "SELECT classification_id, subject_id FROM classification_subjects where classification_id IN (#{classification_ids})"
  c_s_ids = ActiveRecord::Base.connection.select_rows(sql)
  @cache.reset_classification_subjects(c_s_ids)
  subject_ids = c_s_ids.map { |_, subject_id| subject_id }
  @cache.reset_subjects(Subject.unscoped.where(id: subject_ids).load)
  subject_ids
end

def setup_retirement_cache(classifications, subject_ids)
  workflow_ids = classifications.map(&:workflow_id).uniq
  retired_counts = SubjectWorkflowStatus.retired.where(
    subject_id: subject_ids,
    workflow_id: workflow_ids
  ).load
  @cache.reset_subject_workflow_statuses(retired_counts)
end

csv_file_path = "tmp/classifications_#{WORKFLOW_ID}_export.csv"
@cache ||= ClassificationDumpCache.new

CSV.open(csv_file_path, 'wb') do |csv|
  formatter = Formatter::Csv::Classification.new(@cache)
  csv << formatter.headers
  completed_resource_classifications.find_in_batches.with_index do |batch, group|
    puts "Processing group #{group}"
    subject_ids = setup_subjects_cache(batch)
    setup_retirement_cache(batch, subject_ids)
    batch.each do |classification|
      csv << formatter.to_array(classification)
    end
  end
end