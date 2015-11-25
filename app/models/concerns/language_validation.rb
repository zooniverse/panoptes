module LanguageValidation
  extend ActiveSupport::Concern

  def self.lang_regex
    /\A[a-z]{2}(\z|-[A-z]{2})/
  end

  included do
    validates :language, format: {with: LanguageValidation.lang_regex }
  end
end
