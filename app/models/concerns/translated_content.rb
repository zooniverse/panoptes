module TranslatedContent
  extend ActiveSupport::Concern
  include RoleControl::ParentalControlled

  included do
    has_paper_trail skip: [:langauge]
    validates :language, format: {with: /\A[a-z]{2}(\z|-[A-z]{2})/}
    belongs_to translated_for

    can_through_parent translated_for, :show

    can :update do |actor|
      !is_primary? && (parent.can_update?(actor) || is_translator?(actor))
    end
    
    can :destroy do |actor|
      !is_primary? && parent.can_destroy?(actor)
    end
    
  end

  module ClassMethods
    def translated_for
      name[0..-8].downcase.to_sym
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
