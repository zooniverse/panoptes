module Translatable
  extend ActiveSupport::Concern

  included do
    validates :primary_language, format: {with: /\A[a-z]{2}(\z|-[A-z]{2})/}
    has_many content_association, autosave: true, inverse_of: name.downcase.to_sym, dependent: :destroy
    has_one :primary_content, -> (translatable) { where(language: translatable.primary_language) }, class_name: content_model
    can_be_linked content_model.name.underscore.to_sym, :scope_for, :translate, :user

    before_validation do |translatable|
      primary_content_association = translatable.content_association.find do |content|
        content.language == translatable.primary_language
      end
      translatable.primary_content = primary_content_association
    end

    validates content_association, presence: true
    validates :primary_content, presence: true
  end

  module ClassMethods
    def content_association
      "#{model_name.singular}_contents".to_sym
    end

    def content_model
      "#{name}Content".constantize
    end
  end

  def available_languages
    content_association.map { |ca| ca.language.downcase }
  end

  def content_association
    @content_association ||= send(self.class.content_association)
  end
end
