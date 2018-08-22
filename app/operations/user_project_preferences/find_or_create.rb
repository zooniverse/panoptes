module UserProjectPreferences
  class FindOrCreate < Operation
    object :user
    object :project

    def execute
      upp = UserProjectPreference.find_or_initialize_by(project_id: project.id, user_id: user.id)

      if upp.email_communication.nil?
        upp.email_communication = user.project_email_communication
      end

      if upp.new_record? || upp.changed?
        upp.save!
        ProjectClassifiersCountWorker.perform_async(upp.project_id)
      else
        upp.touch
      end

      user.update_column(:project_id, project.id) unless user.project_id

      upp
    end
  end
end
