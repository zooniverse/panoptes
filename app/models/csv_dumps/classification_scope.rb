# frozen_string_literal: true

module CsvDumps
  class ClassificationScope < DumpScope
    attr_reader :cache, :resource_classifications_scope

    def initialize(resource, cache, resource_classifications_scope)
      super(resource)
      @cache = cache
      @resource_classifications_scope = resource_classifications_scope
    end

    def each
      read_from_database do
        completed_resource_classifications.find_in_batches do |batch|
          subject_ids = setup_subjects_cache(batch)
          setup_retirement_cache(batch, subject_ids)
          batch.each do |classification|
            yield classification
          end
        end
      end
    end

    private

    def setup_subjects_cache(classifications)
      classification_ids = classifications.map(&:id).join(",")
      sql = "SELECT classification_id, subject_id FROM classification_subjects where classification_id IN (#{classification_ids})"
      c_s_ids = ActiveRecord::Base.connection.select_rows(sql)
      cache.reset_classification_subjects(c_s_ids)
      subject_ids = c_s_ids.map { |_, subject_id| subject_id }
      cache.reset_subjects(Subject.where(id: subject_ids).load)
      subject_ids
    end

    def completed_resource_classifications
      resource_classifications_scope
        .complete
        .joins(:workflow)
        .where(workflows: { activated_state: 'active' })
        .includes(:user, :workflow)
    end

    def setup_retirement_cache(classifications, subject_ids)
      workflow_ids = classifications.map(&:workflow_id).uniq
      retired_counts = SubjectWorkflowStatus.retired.where(
        subject_id: subject_ids,
        workflow_id: workflow_ids
      ).load
      cache.reset_subject_workflow_statuses(retired_counts)
    end
  end
end
