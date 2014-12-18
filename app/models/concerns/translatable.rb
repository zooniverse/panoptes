module Translatable
  extend ActiveSupport::Concern

  included do
    validates :primary_language, format: {with: /\A[a-z]{2}(\z|-[A-z]{2})/}
    has_many content_association, autosave: true

    can_be_linked content_model.name.underscore.to_sym, :scope_for, :translate, :groups
  end

  module ClassMethods
    def translation_scope
      @translation_scope ||= joins(:access_control_lists)
                           .where.overlap(access_control_lists: { roles: ["translator"] })
    end
    
    def scope_for(action, groups, opts={})
      case action
      when :translate
        translation_scope.where(access_control_lists: { user_group: groups })
      else
        super
      end
    end

    def content_association
      "#{model_name.singular}_contents".to_sym
    end

    def content_model
      "#{name}Content".constantize
    end
  end

  def is_translator?(actor)
    self.class.translatable_by(actor).exists?(id)
  end

  def content_for(languages, fields)
    language = best_match_for(languages)
    content_association.select(*fields).where(language: language).first
  end

  def available_languages
    content_association.select('language').map(&:language).map(&:downcase)
  end

  def content_association
    @content_associattion ||= send(self.class.content_association)
  end

  def primary_content
    send(self.class.content_association).where(language: primary_language).first
  end

  private

  def best_match_for(languages)
    languages = languages.flat_map do |lang|
      if lang.length == 2
        lang
      else
        [lang, lang.split('-').first]
      end
    end
    (languages & available_languages).first || primary_language
  end
end
