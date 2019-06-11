class SubjectMetadataWorker
  include Sidekiq::Worker

  def perform(subject_set_id)
    update_sms_priority_sql = <<-SQL
      UPDATE set_member_subjects
      SET    priority = CAST(subjects.metadata->>'#priority' AS INTEGER)
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
  end
end
