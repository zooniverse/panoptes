module Routes
  module Constraints
    class ProjectTranslations
      PROJECT_REGEX = /project/i
      attr_reader :request

      def matches?(request)
        @request = request

        if show_route?
           valid_show_id? && project_translations_request?
        else
          project_translations_request?
        end
      end

      private

      def project_translations_request?
        !!PROJECT_REGEX.match(request.params[:translated_type])
      end

      def show_route?
        request.params.key?(:id)
      end

      def valid_show_id?
        !!Routes::JsonApiRoutes::VALID_IDS.match(request.params[:id].to_s)
      end
    end
  end
end
