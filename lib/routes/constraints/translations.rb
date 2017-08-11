module Routes
  module Constraints
    module Translations
      attr_reader :ids_regex

      def initialize(ids_regex=nil)
        @ids_regex = ids_regex
      end
    end
  end
end
