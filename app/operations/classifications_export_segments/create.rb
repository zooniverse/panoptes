module ClassificationExportSegments
  class Create < Operation
    integer :workflow_id
    object :requester

    def execute
      workflow = Workflow.find(workflow_id)
      previous_segment = workflow.latest_classifications_export_segment

      segment = previous_segment.next_segment
      segment.requester = requester
      segment.create!

      ClassificationsExportSegmentWorker.perform_async(segment.id, segment.class.name.underscore)
    end
  end
end
