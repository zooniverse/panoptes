module ApiErrors
  class PanoptesApiError < StandardError; end
  class PatchResourceError < PanoptesApiError; end
  class UnauthorizedTokenError < PanoptesApiError; end
  class UnsupportedMediaType < PanoptesApiError; end
  class UserSeenSubjectIdError < PanoptesApiError; end
  class NotLoggedIn < PanoptesApiError; end
  class RolesExist < StandardError
    def initialize
      super("Cannot create roles resource when one exists for the user and project")
    end
  end
end
