class DatabaseReplica
  def self.read(feature_flag_key)
    if Panoptes.flipper.enabled?(feature_flag_key)
      Standby.on_standby do
        yield
      end
    else
      yield
    end
  end
end
