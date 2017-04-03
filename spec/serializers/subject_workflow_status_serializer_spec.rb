require 'spec_helper'

describe SubjectWorkflowStatusSerializer do
  it_should_behave_like "a no count serializer" do
    let(:resource) { create :subject_workflow_status }
  end
end
