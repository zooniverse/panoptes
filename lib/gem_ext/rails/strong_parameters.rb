# frozen_string_literal: true

# backport the strong params nested array fix for permit!
# that is fixed in 5.2+ https://github.com/rails/rails/pull/32593/
# landed in https://github.com/rails/rails/blob/v5.2.8.1/actionpack/CHANGELOG.md#rails-521-august-07-2018
if Gem::Version.new(Rails.version) < Gem::Version.new('5.2')
  module ActionController
    class Parameters
      def permit!
        each_pair do |key, value|
          Array.wrap(value).flatten.each do |v|
            v.permit! if v.respond_to? :permit!
          end
        end

        @permitted = true
        self
      end
    end
  end
end