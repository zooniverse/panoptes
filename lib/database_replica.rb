class DatabaseReplica
  def self.read(feature_flag_key, &block)
    if Panoptes.flipper.enabled?(feature_flag_key)
      # read via the replica settings using Standby gem
      Standby.on_standby do
        read_with_timeouts(&block)
      end
    else
      read_with_timeouts(&block)
    end
  end

  # allow dump workers to have twice the length of time to query data from
  # the database vs the defaults for long running query times
  # introduce in https://github.com/zooniverse/Panoptes/pull/3278
  def self.read_with_timeouts
    begin
      # double the statement timeout for dump workers
      ActiveRecord::Base.connection.execute(
        "SET statement_timeout = #{(Panoptes.pg_statement_timeout * 2).to_i}"
      )

      yield

    ensure
      # reset back to the default for subsequent connection re-use
      ActiveRecord::Base.connection.execute(
        "SET statement_timeout = #{Panoptes.pg_statement_timeout}"
      )
    end
  end
end
