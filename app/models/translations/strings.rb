module Translations
  class Strings
    def self.compare(old, new)
      (new.keys - old.keys).each do |key|
        yield :added, key
      end

      old.keys.select do |key|
        if new.key?(key)
          if old[key] != new[key]
            yield :changed, key
          end
        else
          yield :removed, key
        end
      end
    end
  end
end
