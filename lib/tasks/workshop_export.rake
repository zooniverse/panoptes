namespace :ali do
  desc "Export of Wildcam for Ali's workshop (feel free to remove after 1 nov)"
  task :export_wildcam do
    project_id = {'development' => 593, 'staging' => 937, 'production' => 593}.fetch(Rails.env)
    user_id = {'development' => 5253, 'staging' => 115, 'production' => 5253}.fetch(Rails.env)

    project = Project.find(project_id)
    user = User.find(user_id)

    media_create_params = {content_type: 'text/csv', metadata: {state: 'creating', recipients: [user.id]}}
    if medium = project.classifications_export
      medium.update!(media_create_params)
      medium.touch
      medium
    else
      medium = project.create_classifications_export!(media_create_params)
    end

    class AliDump < ClassificationsDumpWorker

      def dump_target
        @dump_target ||= ClassificationsDumpWorker.to_s.underscore.match(/\A(\w+)_dump_worker\z/)[1]
      end

      def completed_project_classifications
        project.classifications.where(user_id: User.where("display_name ILIKE 'hhmi%'"))
        .complete
        .joins(:workflow)
        .includes(:user, workflow: [:workflow_contents])
      end
    end

    dump_worker = AliDump.new
    dump_worker.perform(project.id, medium.id)
  end
end
