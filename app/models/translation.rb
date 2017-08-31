class Translation < ActiveRecord::Base
  belongs_to :translated, polymorphic: true, required: true
  validate :validate_strings

  # TODO: add a unique validation for translated_type, id, language

  # TODO: Look at adding in paper trail change tracking for laguage / strings here

  def self.translated_model_names
    @translated_class_names ||= [].tap do |translated|
      ActiveRecord::Base.subclasses.each do |klass|
        klass_associations = klass.reflect_on_all_associations
        translated_associations = klass_associations.select do |assoc|
          assoc.options[:as] == :translated
        end

        unless translated_associations.empty?
          translated << klass.model_name
        end
      end
    end
  end

  private

  def validate_strings
    unless strings.is_a?(Hash)
      errors.add(:strings, "must be present but can be empty")
    end
  end
end
