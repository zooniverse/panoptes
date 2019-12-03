class SubjectMetadataWorker
  include Sidekiq::Worker

  def perform(subject_set_id, subject_ids)
    if ActiveRecord::VERSION::MAJOR == 5
      update_sms_priority_sql = <<-SQL
        UPDATE set_member_subjects
        SET    priority = CAST(subjects.metadata->>'#priority' AS NUMERIC)
        FROM   subjects
        WHERE  subjects.id = set_member_subjects.subject_id
        AND    subjects.metadata ? '#priority'
        AND    set_member_subjects.priority IS NULL
        AND    set_member_subjects.subject_set_id IN $1
        AND    set_member_subjects.subject_id IN $2
      SQL
      ActiveRecord::Base.connection.exec_update(
        update_sms_priority_sql,
        "SQL",
        [[nil, subject_set_id], [nil, subject_ids]]
      )
    else
      update_sms_priority_sql = <<-SQL
        UPDATE set_member_subjects
        SET    priority = CAST(subjects.metadata->>'#priority' AS NUMERIC)
        FROM   subjects
        WHERE  subjects.id = set_member_subjects.subject_id
        AND    subjects.metadata ? '#priority'
        AND    set_member_subjects.priority IS NULL
        AND    set_member_subjects.subject_set_id = :subject_set_id
        AND    set_member_subjects.subject_id IN (:subject_ids)
      SQL
      # handle incorrect bind params for non preparted statements
      # in exec_update, fixed in rails 5
      # https://github.com/rails/rails/issues/24893
      # https://github.com/rails/rails/issues/34183
      bound_update_sms_priority_sql = ActiveRecord::Base.send(
        :replace_named_bind_variables,
        update_sms_priority_sql,
        subject_ids: subject_ids, subject_set_id: subject_set_id
      )
      ActiveRecord::Base.connection.exec_update(
        bound_update_sms_priority_sql,
        "SQL",
        []
      )
    end
  end
end
