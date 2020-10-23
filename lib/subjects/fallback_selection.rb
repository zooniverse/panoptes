module Subjects
  class FallbackSelection
    attr_reader :workflow, :limit, :options

    def self.num_training_subjects_denominator
      ENV.fetch('FALLBACK_NUM_TRAINING_SUBJECTS_DENOMINATOR', 10)
    end

    def initialize(workflow, limit, options = {})
      @workflow, @limit, @options = workflow, limit, options
    end

    def any_workflow_data
      if workflow.grouped
        fallback_grouped_selection.shuffle
      else
        fallback_selection.shuffle
      end
    end

    private

    def fallback_grouped_selection
      unless (subject_set_id = options[:subject_set_id])
        raise Subjects::Selector::MissingParameter, 'subject_set_id parameter missing for grouped workflow'
      end

      workflow
        .set_member_subjects
        .where(subject_set_id: subject_set_id)
        .limit(limit)
        .pluck('set_member_subjects.subject_id')
    end

    def fallback_selection
      (non_training_subject_ids | training_subject_ids)
    end

    def non_training_subject_ids
      SetMemberSubject
        .where(subject_set_id: workflow.non_training_subject_set_ids)
        .limit(non_training_limit)
        .pluck('set_member_subjects.subject_id')
    end

    def training_subject_ids
      return [] if workflow.training_set_ids.empty?

      SetMemberSubject
        .where(subject_set_id: workflow.training_set_ids)
        .limit(training_limit)
        .pluck('set_member_subjects.subject_id')
    end

    # by default a ~10:1 ratio of real subjects to training
    # modify this ration by num_training_subjects_limit class method
    def training_limit
      @training_limit ||= (limit.to_f / self.class.num_training_subjects_denominator).round
    end

    # respect the original request limit
    def non_training_limit
      limit - training_limit
    end
  end
end
