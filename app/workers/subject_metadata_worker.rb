class SubjectMetadataWorker
  include Sidekiq::Worker
  attr_reader :sms_ids

  sidekiq_options retry: 10, dead: false

  def perform(sms_ids)
    return if Panoptes.flipper[:skip_subject_metadata_worker].enabled?

    @sms_ids = sms_ids
    check_sms_resources_exist
    if ActiveRecord::VERSION::MAJOR == 5
      run_ar5_update
    else
      run_ar4_update
    end
  end

  private

  def check_sms_resources_exist
    return if SetMemberSubject.exists?(id: sms_ids)

    raise(
      ActiveRecord::RecordNotFound,
      "Couldn't find all SetMemberSubjects with 'id': (#{sms_ids.join(',')})"
    )
  end

  def run_ar5_update
    update_sms_priority_sql =
      <<-SQL
        UPDATE set_member_subjects
        SET    priority = CAST(subjects.metadata->>'#priority' AS NUMERIC)
        FROM   subjects
        WHERE  subjects.id = set_member_subjects.subject_id
        AND    subjects.metadata ? '#priority'
        AND    set_member_subjects.id IN $1
      SQL
    ActiveRecord::Base.connection.exec_update(
      update_sms_priority_sql,
      'SQL',
      [[nil, sms_ids]]
    )
  end

  def run_ar4_update
    update_sms_priority_sql =
      <<-SQL
        UPDATE set_member_subjects
        SET    priority = CAST(subjects.metadata->>'#priority' AS NUMERIC)
        FROM   subjects
        WHERE  subjects.id = set_member_subjects.subject_id
        AND    subjects.metadata ? '#priority'
        AND    set_member_subjects.id IN (:sms_ids)
      SQL
    # handle incorrect bind params for non preparted statements
    # in exec_update, fixed in rails 5
    # https://github.com/rails/rails/issues/24893
    # https://github.com/rails/rails/issues/34183
    bound_update_sms_priority_sql = ActiveRecord::Base.send(
      :replace_named_bind_variables,
      update_sms_priority_sql,
      sms_ids: sms_ids
    )
    ActiveRecord::Base.connection.exec_update(
      bound_update_sms_priority_sql,
      'SQL',
      []
    )
  end
end
