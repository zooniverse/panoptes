module Formatter
  module Csv
    class UserEmail
      def headers
        false
      end

      def to_rows(user)
        [to_array(user)]
      end

      def to_array(user)
        [user.email]
      end
    end
  end
end
