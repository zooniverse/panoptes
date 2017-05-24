module UserProjectPreferences
  class FindOrCreateUponClassification < Operation
    object :api_user, default: nil
    object :user
    object :project

    def execute
      user_project_preference = UserProjectPreference.transaction do
        upp = UserProjectPreference.find_or_initialize_by(project_id: project.id, user_id: user.id)

        if upp.email_communication.nil?
          upp.email_communication = user.project_email_communication
        end

        if upp.new_record? || upp.changed?
          upp.save!
        else
          upp.touch
        end

        user.update_column(:project_id, project.id) unless user.project_id
        upp
      end

      ProjectClassifiersCountWorker.perform_async(project.id)
      user_project_preference
    end
  end
end
