module ModelVersion

  def self.index_number(versioned_model)
    if versioned_model && last_version = versioned_model.versions.last
      last_version.index + 1
    else
      1
    end
  end
end
