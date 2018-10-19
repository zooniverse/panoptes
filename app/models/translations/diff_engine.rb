module Translations
  class DiffEngine
    attr_reader :translation

    def initialize(translation)
      @translation = translation
    end

    # TODO: Can this method name be improved to indicate which is the primary
    # language, and which is the one with possibly outdated strings?
    def outdated(other)
      translation.strings.keys.select do |key|
        next true unless other.strings.key?(key)
        next true unless translation.string_versions.key?(key)
        next true unless other.string_versions.key?(key)

        translation.string_versions[key] > other.string_versions[key]
      end
    end
  end
end
