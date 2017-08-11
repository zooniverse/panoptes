module Routes
  module Constraints
    class ProjectTranslations
      include Translations

      PROJECT_REGEX = /project/i

      def matches?(request)
        projects_resource = PROJECT_REGEX.match(request.params[:translated_type])

        if ids_regex
           ids_regex.match(request.params[:id]) & projects_resource
        else
          projects_resource
        end
      end
    end
  end
end
