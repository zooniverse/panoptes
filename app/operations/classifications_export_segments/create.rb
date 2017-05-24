module ClassificationsExportSegments
  class Create < Operation
    hash :links do
      integer :workflow
    end

    def execute
      previous_segment = workflow.latest_classifications_export_segment

      segment = if previous_segment
                  previous_segment.next_segment
                else
                  initial_segment(workflow)
                end

      segment.requester = requester

      if segment.save
        ClassificationsExportSegmentWorker.perform_async(segment.id, segment.class.name.underscore)
        segment
      else
        nil
      end
    end

    private

    def workflow
      @workflow ||= Workflow.find(links[:workflow])
    end

    def initial_segment(workflow)
      segment = workflow.classifications_export_segments.build(project_id: workflow.project_id)
      segment.set_first_last_classifications(nil)
      segment
    end

    def requester
      api_user.user
    end
  end
end
