class SubjectMetadataWorker
  include Sidekiq::Worker
  attr_reader :sms_ids

  sidekiq_options retry: 10, dead: false

  def perform(sms_ids)
    return if Flipper.enabled?(:skip_subject_metadata_worker)

    @sms_ids = sms_ids
    check_sms_resources_exist
    run_update
  end

  private

  def check_sms_resources_exist
    return if SetMemberSubject.exists?(id: sms_ids)

    raise(
      ActiveRecord::RecordNotFound,
      "Couldn't find all SetMemberSubjects with 'id': (#{sms_ids.join(',')})"
    )
  end

  def run_update
    update_sms_priority_sql = ActiveRecord::Base.sanitize_sql_array([
      <<-SQL.squish,
        UPDATE set_member_subjects
        SET    priority = CAST(subjects.metadata->>'#priority' AS NUMERIC)
        FROM   subjects
        WHERE  subjects.id = set_member_subjects.subject_id
        AND    subjects.metadata ? '#priority'
        AND    set_member_subjects.id IN (:sms_ids)
      SQL
      { sms_ids: sms_ids }
    ])
    ActiveRecord::Base.connection.exec_update(
      update_sms_priority_sql,
      'SubjectMetadataUpdate',
      []
    )
  end
end
