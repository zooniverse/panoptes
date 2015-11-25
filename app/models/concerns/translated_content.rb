module TranslatedContent
  extend ActiveSupport::Concern
  include RoleControl::ParentalControlled

  included do
    has_paper_trail skip: [:langauge]
    validates :language, format: {with: LanguageValidation.lang_regex}
    belongs_to translated_for

    can_through_parent translated_for, :show, :index, :versions, :version
  end

  module ClassMethods
    def translated_for
      name[0..-8].downcase.to_sym
    end

    def translated_class
      translated_for.to_s.camelize.constantize
    end

    def scope_for(action, user, opts={})
      case action
      when :show, :index
        super
      else
        joins(translated_for)
          .merge(translated_class.scope_for(:translate, user, opts))
          .where.not("\"#{translated_class.table_name}\".\"primary_language\" = \"#{table_name}\".\"language\"")
      end
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
