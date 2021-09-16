# frozen_string_literal: true

class SubjectSetCompletenessWorker
  include Sidekiq::Worker
  using Refinements::RangeClamping

  sidekiq_options queue: :data_low

  sidekiq_options congestion: {
    interval: 30, # N jobs (below) in each 30s
    max_in_interval: 1, # only 1 job every interval above
    min_delay: 60, # next job can run 60s after the last one
    reject_with: :reschedule, # reschedule the job to run later (avoid db pressure) so we don't eventually run all the jobs and the stored metrics eventually align
    key: ->(subject_set_id, workflow_id) { "subject_set_#{subject_set_id}_completeness_#{workflow_id}_worker" }
  }

  sidekiq_options lock: :until_executing

  def perform(subject_set_id, workflow_id)
    subject_set = SubjectSet.find(subject_set_id)
    workflow = Workflow.find_without_json_attrs(workflow_id)

    # find the count of all retired subjects, for a known subject set, in the context of a known workflow
    # using the read replica if the feature flag is enabled
    retired_subjects_completeness = 0.0
    DatabaseReplica.read('subject_set_completeness_from_read_replica') do
      retired_subjects_count = SubjectSetWorkflowCounter.new(subject_set.id, workflow.id).retired_subjects * 1.0
      total_subjects_count = subject_set.set_member_subjects_count * 1.0
      # calculate and clamp the completeness value between 0.0 and 1.0, i.e. 0 to 100%
      retired_subjects_completeness = (0.0..1.0).clamp(retired_subjects_count / total_subjects_count)
    end

    # store these per workflow completeness metric in a json object keyed by the workflow id
    # use the atomic DB json operator to avoid clobbering data in the jsonb attribute by other updates
    # https://www.postgresql.org/docs/11/functions-json.html
    SubjectSet.where(id: subject_set.id).update_all(
      "completeness = jsonb_set(completeness, '{#{workflow_id}}', '#{retired_subjects_completeness}', true)"
    )
  rescue ActiveRecord::RecordNotFound
    # avoid running sql count queries for subject sets and workflows we can't find
  end
end
