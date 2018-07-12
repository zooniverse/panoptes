module TranslatedContent
  extend ActiveSupport::Concern

  included do
    has_paper_trail ignore: [:language]
    validates :language, format: {with: LanguageValidation.lang_regex}
    belongs_to translated_for, touch: true
  end

  module ClassMethods
    def translated_for
      name[0..-8].downcase.to_sym
    end

    def translated_class
      translated_for.to_s.camelize.constantize
    end
  end

  def is_translator?(actor)
    parent.is_translator?(actor)
  end

  def is_primary?
    language == parent.primary_language
  end

  private

  def parent
    send(self.class.translated_for)
  end
end
