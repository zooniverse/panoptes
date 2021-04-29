require 'spec_helper'

describe Workflows::UnretireSubjects do 
    let(:api_user) { ApiUser.new(build_stubbed(:user)) }
    let (:workflow) { create(:workflow) }
    let(:subject_set) { create(:subject_set, project: workflow.project, workflows: [workflow]) }
    let(:subject_set_id) { subject_set.id }
    let(:subject1) { create(:subject, subject_sets: [subject_set] ) }
    let(:subject_workflow_count) { create() }
    let(:params) do
        {
          workflow_id: workflow.id,
          subject_id: subject1.id,
        }
      end

    it "should unretire given subjects with subject ids for the workflow", :focus => true do 
        result = operation.run(params)
        SubjectWorkflowStatus
    end
end