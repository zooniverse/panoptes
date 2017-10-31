module Routes
  module Constraints
    class Translations
      attr_reader :params

      def matches?(request)
        @params = request.params

        if show_route?
           valid_show_id? && has_translated_type_param?
        else
          has_translated_type_param?
        end
      end

      private

      def has_translated_type_param?
        !!params.dig(:translations, :translated_type)
      end

      def show_route?
        params.key?(:id)
      end

      def valid_show_id?
        !!Routes::JsonApiRoutes::VALID_IDS.match(params[:id].to_s)
      end
    end
  end
end
