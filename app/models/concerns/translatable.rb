# This module should be included in any model class that is
# a valid target for the Translation model.
module Translatable
  extend ActiveSupport::Concern

  included do
    has_many :translations, as: :translated, dependent: :destroy
  end

  module ClassMethods
    def translatable_attributes
      raise NotImplementedError, "Translatable model needs to specify which attributes are translatable."
    end
  end

  def primary_language_translation
    if respond_to?(:primary_language)
      translations.find_by(language: primary_language)
    else
      translations.find_by(language: language)
    end
  end
end
