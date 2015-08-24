module ModelVersion

  def self.index_number(versioned_model)
    return unless versioned_model
    if versioned_model.live?
      versioned_model.versions.last.index + 1
    elsif versioned_model.respond_to?(:version)
      versioned_model.version.index
    else
      1
    end
  end
end
