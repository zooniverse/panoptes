module Translatable
  extend ActiveSupport::Concern

  included do
    validates :primary_language, format: {with: /\A[a-z]{2}(\z|-[A-z]{2})/}
    has_one content_association, autosave: true, inverse_of: name.downcase.to_sym, class_name: content_model, dependent: :destroy
    can_be_linked content_model.name.underscore.to_sym, :scope_for, :translate, :user

    validates content_association, presence: true
  end

  module ClassMethods
    def content_association
      "#{model_name.singular}_contents".to_sym
    end

    def content_model
      "#{name}Content".constantize
    end
  end

  # this should really go away
  # or get updated from all the translation resource via workers
  def available_languages
    [content_association.language.downcase]
  end

  def content_association
    @content_association ||= send(self.class.content_association)
  end
end
