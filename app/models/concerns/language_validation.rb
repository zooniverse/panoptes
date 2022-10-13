module LanguageValidation
  extend ActiveSupport::Concern

  def self.lang_regex
    # match language codes with possible subtags en-GB, en, en-US, en-us etc
    # https://en.wikipedia.org/wiki/IETF_language_tag
    /\A[a-z]{2}-?(?:[a-z]{2,3})?\z/i
  end

  included do
    validates :language, format: { with: LanguageValidation.lang_regex }
  end
end
