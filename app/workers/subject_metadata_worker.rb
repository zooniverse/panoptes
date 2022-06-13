class SubjectMetadataWorker
  include Sidekiq::Worker
  attr_reader :sms_ids

  sidekiq_options retry: 10, dead: false

  def perform(sms_ids)
    return if Panoptes.flipper[:skip_subject_metadata_worker].enabled?

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
    update_sms_priority_sql =
      <<-SQL.squish
        UPDATE set_member_subjects
        SET    priority = CAST(subjects.metadata->>'#priority' AS NUMERIC)
        FROM   subjects
        WHERE  subjects.id = set_member_subjects.subject_id
        AND    subjects.metadata ? '#priority'
        AND    set_member_subjects.id IN (:sms_ids)
      SQL
    # handle missing bind params for non prepared statements
    # by manually binding the named vars into the sql via `replace_named_bind_variables`
    # https://github.com/rails/rails/issues/24893
    # https://github.com/rails/rails/issues/34183
    # call to exec_no_cache doesn't pass the bind params - so we need to morph them ourselves via sql
    # https://github.com/rails/rails/blob/v5.0.7.2/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L587
    # fixed in rails 6.1 by the look - so in theory can switch to bound params without sql string morphing once there
    # https://github.com/rails/rails/blob/v6.1.5.1/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L649
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
