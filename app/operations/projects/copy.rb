# frozen_string_literal: true

module Projects
  class Copy < Operation
    object :project
    object :user, class: ApiUser, default: -> { api_user }

    validates :user, presence: true

    def execute
      ProjectCopier.new(project.id, user.id).copy
    end
  end
end
