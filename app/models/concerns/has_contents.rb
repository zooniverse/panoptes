module HasContents
  extend ActiveSupport::Concern

  included do
    validates :primary_language, format: {with: /\A[a-z]{2}(\z|-[A-z]{2})/}
    has_many content_association, autosave: true, inverse_of: name.downcase.to_sym, dependent: :destroy

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

  def available_languages
    content_association.map { |ca| ca.language.downcase }
  end

  def content_association
    @content_association ||= send(self.class.content_association)
  end

  # TODO: this should become the association instead of the has_many
  def primary_content
    @primary_content ||= if content_association.loaded?
                           content_association.to_a.find do |content|
                             content.language == primary_language
                           end
                         else
                           content_association.find_by(language: primary_language)
                         end
  end
end
