module Versioning
  extend ActiveSupport::Concern

  class ConfigurationError < StandardError; end

  included do
    @versioned_association = nil
    @versioned_attributes = []

    after_save :save_version
  end

  module ClassMethods
    def versioned(association:, attributes:)
      @versioned_association = association
      @versioned_attributes = attributes.map(&:to_s)
    end

    def versioned_association
      @versioned_association
    end

    def versioned_attributes
      @versioned_attributes
    end
  end

  # Create a new version record if any of the attributes that fall under the
  # versioning have been changed. Capture all of the versioned attributes in
  # each version, not just the changed ones.
  def save_version
    unless self.class.versioned_association.present?
      raise ConfigurationError, "Must call `versioned` DSL method if you include the Versioned module"
    end
    if (saved_changes.keys & self.class.versioned_attributes).present?
      build_version.save!
    end
  end

  def build_version
    send(self.class.versioned_association).build(
      attributes.slice(*self.class.versioned_attributes)
    )
  end

  # take the highest associated version_id
  # via the autoincrementing PK of the versioned_association
  def latest_version_id
    version_ids.max
  end

  def version_ids
    send(self.class.versioned_association).pluck(:id)
  end
end
