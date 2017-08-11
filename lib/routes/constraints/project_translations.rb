module Routes
  module Constraints
    class ProjectTranslations
      include Translations

      PROJECT_REGEX = /project/i

      def matches?(request)
        project_resource = project_translations_request?(
          request.params[:translated_type]
        )

        if ids_regex
           ids_regex.match(request.params[:id]) && project_resource
        else
          project_resource
        end
      end

      private

      def project_translations_request?(translated_resource_type)
        !!PROJECT_REGEX.match(translated_resource_type)
      end
    end
  end
end
