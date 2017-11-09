module Formatter
  module Csv
    class UserEmail
      def headers
        false
      end

      def to_rows(user)
        [
          [user.email]
        ]
      end
    end
  end
end
