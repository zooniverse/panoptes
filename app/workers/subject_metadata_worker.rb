class SubjectMetadataWorker
  include Sidekiq::Worker

  def perform(set_id)

    smses = SetMemberSubject.where(subject_set_id: set_id)

    update_sms_priority_sql = <<-SQL
      UPDATE set_member_subjects
      SET    priority = CAST(subjects.metadata->>'#priority' AS INTEGER)
      FROM   subjects
      WHERE  subjects.id = set_member_subjects.subject_id
      AND    set_member_subjects.id IN (?)
    SQL

    bound_update_sms_priority_sql = ActiveRecord::Base.send(
      :replace_bind_variables,
      update_sms_priority_sql,
      [smses.pluck(:id)]
    )

    ActiveRecord::Base.connection.exec_update(bound_update_sms_priority_sql)
  end
end
