class DatabaseReplica
  def self.read(feature_flag_key)
    if Panoptes.flipper.enabled?(feature_flag_key)
      # read via the replica settings using Standby gem
      Standby.on_standby { yield }
    else
      yield
    end
  end

  # avoid connection timeouts: introduced in https://github.com/zooniverse/Panoptes/pull/3278
  # allow dump workers to have unlimited query time to fetch data
  # and ensure we reset the connection timeout back to default after query
  def self.read_without_timeout(feature_flag_key, &block)
    if Panoptes.flipper.enabled?(feature_flag_key)
      # read via the replica settings using Standby gem
      Standby.on_standby do
        execute_without_timeout(&block)
      end
    else
      execute_without_timeout(&block)
    end
  end

  def self.execute_without_timeout
    # disable the statement timeout
    ActiveRecord::Base.connection.execute('SET statement_timeout = 0')

    yield
  ensure
    # reset back to the default for subsequent connection re-use
    ActiveRecord::Base.connection.execute(
      "SET statement_timeout = #{Panoptes.pg_statement_timeout}"
    )
  end
  private_class_method :execute_without_timeout
end
