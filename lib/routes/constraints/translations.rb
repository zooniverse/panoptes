module Routes
  module Constraints
    class Translations
      attr_reader :request, :params

      def matches?(request)
        @request = request
        @params = request.params

        if create_route? || index_route?
          has_translated_type_param?
        elsif show_route? || update_route?
          valid_show_id?
        else
          false
        end
      end

      private

      def show_route?
        params.key?(:id)
      end

      def update_route?
         request.put? || request.patch?
      end

      def create_route?
        request.post?
      end

      def index_route?
        request.get? && !show_route?
      end

      def has_translated_type_param?
        !!params.dig(:translations, :translated_type)
      end

      def valid_show_id?
        !!Routes::JsonApiRoutes::VALID_IDS.match(params[:id].to_s)
      end
    end
  end
end
