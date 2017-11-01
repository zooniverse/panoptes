module Routes
  module Constraints
    class Translations
      attr_reader :params

      def matches?(request)
        @params = request.params

        if member_route?
           valid_show_id? && has_translated_type_param?
        else
          # all polymorphic controllers need to supply the translated resource
          # type to correctly wire up the controller authorization scopes
          has_translated_type_param?
        end
      end

      private

      def member_route?
        params.key?(:id)
      end

      def has_translated_type_param?
        params.key?(:translated_type)
      end

      def valid_show_id?
        !!Routes::JsonApiRoutes::VALID_IDS.match(params[:id].to_s)
      end
    end
  end
end
