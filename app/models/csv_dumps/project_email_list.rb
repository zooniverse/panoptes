module CsvDumps
  class ProjectEmailList < DumpScope
    def initialize(project_id)
      @project_id = project_id
    end

    def each
      read_from_database do
        user_emails.find_each do |user|
          yield user
        end
      end
    end

    def user_emails
      User
        .joins(:project_preferences)
        .where(user_project_preferences: { project_id: @project_id, email_communication: true })
        .active
        .where(valid_email: true)
        .select(:id, :email)
    end
  end
end
