# frozen_string_literal: true

module Projects
  class Copy < Operation
    object :project
    object :user, class: ApiUser, default: -> { api_user }
    string :create_subject_set, default: nil

    validates :user, presence: true

    def execute
      Project.transaction do
        copied_project = ProjectCopier.new(project.id, user.id).copy

        # create? a new empty subject set for uploading data with the newly copied a project
        copied_project.subject_sets.create!(display_name: create_subject_set) if create_subject_set

        copied_project
      end
    end
  end
end
