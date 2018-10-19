module Translations
  class HashDiff
    def self.diff(a, b)
      a.keys.select do |key|
        next true unless b.key?(key)
        a[key] != b[key]
      end
    end
  end
end
