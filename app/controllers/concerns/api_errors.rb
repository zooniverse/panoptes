module ApiErrors
  class PanoptesApiError < StandardError; end
  class PatchResourceError < PanoptesApiError; end
  class UnauthorizedTokenError < PanoptesApiError; end
  class UnsupportedMediaType < PanoptesApiError; end
  class UserSeenSubjectIdError < PanoptesApiError; end
  class NotLoggedIn< PanoptesApiError; end
end
