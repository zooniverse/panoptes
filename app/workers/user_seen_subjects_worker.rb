class UserSeenSubjectsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high, lock: :while_executing, lock_args_method: ->(args) { [ args[0], args[1] ] }, on_conflict: :reschedule

  def perform(user_id, workflow_id, subject_ids)
    user = User.find(user_id)
    workflow = Workflow.find_without_json_attrs(workflow_id)

    UserSeenSubject.add_seen_subjects_for_user(
      user: user,
      workflow: workflow,
      subject_ids: subject_ids
    )
  rescue ActiveRecord::RecordNotFound
  end
end
