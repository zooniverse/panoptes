module ApiErrors
  class PanoptesApiError < StandardError; end
  class PatchResourceError < PanoptesApiError; end
  class UnauthorizedTokenError < PanoptesApiError; end
  class UnsupportedMediaType < PanoptesApiError; end
  class UserSeenSubjectIdError < PanoptesApiError; end
  class NotLoggedIn < PanoptesApiError; end
  class NoUserError < PanoptesApiError; end
  class UnpermittedParameter < PanoptesApiError; end
  class LiveProjectChanges < PanoptesApiError; end
  class NoMediaError < PanoptesApiError
    def initialize(media_type, parent, parent_id, media_id=nil)
      super("No #{media_type}#{ media_string(media_id) }exists for #{parent} ##{parent_id}")
    end

    def media_string(media_id)
      return ' ' unless media_id
      " ##{media_id} "
    end
  end
  class LimitExceeded < PanoptesApiError; end
  class RolesExist < StandardError
    def initialize
      super("Cannot create roles resource when one exists for the user and project")
    end
  end
end
