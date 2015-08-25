module ModelVersion

  def self.version_number(model_version)
    return default_version_num unless model_version
    if model_version.live?
      if latest_version = model_version.versions.last
        latest_version.index + 1
      else
        default_version_num
      end
    else
      model_version.version.index
    end
  end

  def self.default_version_num
    1
  end
end
