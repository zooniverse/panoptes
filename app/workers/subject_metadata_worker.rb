class SubjectMetadataWorker
  include Sidekiq::Worker

  def perform(subject_set_id)
    # add feature flag for runtime behaviour change
    # sometimes this update query takes minutes to run
    # the DB CPU spikes and queues are blocked
    # with these workers
    return if Panoptes.flipper[:skip_subject_metadata_worker].enabled?

    if ActiveRecord::VERSION::MAJOR == 5
      update_sms_priority_sql = <<-SQL
        UPDATE set_member_subjects
        SET    priority = CAST(subjects.metadata->>'#priority' AS NUMERIC)
        FROM   subjects
        WHERE  subjects.id = set_member_subjects.subject_id
        AND    subjects.metadata ? '#priority'
        AND    set_member_subjects.subject_set_id = $1
      SQL
      ActiveRecord::Base.connection.exec_update(
        update_sms_priority_sql,
        "SQL",
        [[nil, subject_set_id]]
      )
    else
      update_sms_priority_sql = <<-SQL
        UPDATE set_member_subjects
        SET    priority = CAST(subjects.metadata->>'#priority' AS NUMERIC)
        FROM   subjects
        WHERE  subjects.id = set_member_subjects.subject_id
        AND    subjects.metadata ? '#priority'
        AND    set_member_subjects.subject_set_id = :subject_set_id
      SQL
      # handle incorrect bind params for non preparted statements
      # in exec_update, fixed in rails 5
      # https://github.com/rails/rails/issues/24893
      # https://github.com/rails/rails/issues/34183
      bound_update_sms_priority_sql = ActiveRecord::Base.send(
        :replace_named_bind_variables,
        update_sms_priority_sql,
        {subject_set_id: subject_set_id}
      )
      ActiveRecord::Base.connection.exec_update(
        bound_update_sms_priority_sql,
        "SQL",
        []
      )
    end
  end
end
