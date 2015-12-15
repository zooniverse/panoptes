module Warehouse
  class ClassificationsDump
    attr_reader :project, :cache, :formatter, :date_range

    def initialize(project, obfuscate_private_details: true, date_range: nil)
      @project = project
      @cache = ClassificationDumpCache.new
      @formatter = ClassificationFormatter.new(project, cache, obfuscate_private_details: obfuscate_private_details)
      @date_range = date_range
    end

    def write_to(output)
      output <<  formatter.class.headers

      completed_project_classifications.find_in_batches do |group|
        update_cache(group)

        group.each do |classification|
          output << formatter.to_array(classification)
        end
      end

      output
    end

    def completed_project_classifications
      scope = project.classifications.complete.joins(:workflow).includes(:user, :subjects, workflow: [:workflow_contents])

      if date_range
        scope = scope.where("classifications.created_at > ? AND classifications.created_at <= ?", date_range.begin, date_range.end)
      end

      scope
    end

    def update_cache(group)
      subject_ids = group.flat_map(&:subject_ids).uniq
      workflow_ids = group.map(&:workflow_id).uniq

      cache.reset_subjects(Subject.where(id: subject_ids).load)
      cache.reset_subject_workflow_counts(SubjectWorkflowCount.retired.where(subject_id: subject_ids, workflow_id: workflow_ids).load)
    end
  end
end
