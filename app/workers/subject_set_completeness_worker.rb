# frozen_string_literal: true

class SubjectSetCompletenessWorker
  include Sidekiq::Worker
  using Refinements::RangeClamping

  class EmptySubjectSet < StandardError; end

  attr_reader :subject_set, :workflow

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
    @subject_set = SubjectSet.find(subject_set_id)
    @workflow = Workflow.find_without_json_attrs(workflow_id)

    subject_set_completeness = calculate_subject_set_completeness
    # store these per workflow completeness metric in a json object keyed by the workflow id
    # use the atomic DB json operator to avoid clobbering data in the jsonb attribute by other updates
    # https://www.postgresql.org/docs/11/functions-json.html
    SubjectSet.where(id: subject_set.id).update_all(
      "completeness = jsonb_set(completeness, '{#{workflow_id}}', '#{subject_set_completeness}', true)"
    )

    run_subject_set_completion_events if subject_set_completed?(subject_set_completeness)
  rescue ActiveRecord::RecordNotFound
    # avoid running sql count queries for subject sets and workflows we can't find
  end

  private

  # find the proportion of all retired subjects, for a known subject set, in the context of a known workflow
  def calculate_subject_set_completeness
    # use the read replica if the feature flag is enabled
    DatabaseReplica.read('subject_set_completeness_from_read_replica') do
      retired_subjects_count = SubjectSetWorkflowCounter.new(subject_set.id, workflow.id).retired_subjects * 1.0
      total_subjects_count = subject_set.set_member_subjects_count * 1.0

      # avoid trying to set NaN in the DB
      raise EmptySubjectSet, "No subjets in subject set: #{subject_set.id}" if total_subjects_count.zero?

      # calculate and clamp the completeness value between 0.0 and 1.0, i.e. 0 to 100%
      (0.0..1.0).clamp(retired_subjects_count / total_subjects_count)
    end
  end

# TODO: the below is starting to look like an operation class
# where we encapsulat the logic on completion events
  def subject_set_completed?(completeness)
    completeness.to_i == 1
  end

  def run_subject_set_completion_events
    create_workflow_classifications_export
    notify_project_team
  end

  def notify_project_team
    # allow project teams to configure their project notification emails
    return unless subject_set.project.notify_on_subject_set_completion?

    SubjectSetCompletedMailerWorker.perform_async(subject_set.id)
  end

  def create_workflow_classifications_export
    requesting_user = ApiUser.new(nil) # use nil to avoid rate limiting exports
    # do we want to have this run for all projects when their sets complete??

    # perhaps we can use another project / workflow level configuration setting?

    # if we use a configuration setting - we can't let user's self assign this one
    # to avoid the rate limiting feature of the exports (or should we use that?)

    # ALTERNATIVELY - can we reimaging exports at the subject set level?
    # would this work with our existing Lab / Client tools to avoid issues with rate limiting, etc here?

    # CreateClassificationsExport.with( api_user: , object: workflow ).run!(params)
    # ClassificationsDumpWorker.perform_async(subject_set.project, resource_type, medium_id=nil, requester_id=nil, *args)
  end
end
