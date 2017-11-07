module Formatter
  module Csv
    class UserEmail
      def self.headers
        false
      end

      def to_array(user)
        [user.email]
      end
    end
  end
end
