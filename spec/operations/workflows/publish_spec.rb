require 'spec_helper'

describe Workflows::Publish do
  let(:user) { create :user }
  let(:project) { create :project, owner: user }
  let(:workflow) { create :workflow, project: project }
  let(:api_user) { ApiUser.new(user) }
  let(:operation) { described_class.with(api_user: api_user) }

  it 'creates a new version' do
    operation.run! workflow: workflow
    expect(workflow.workflow_versions.count).to eq(1)
  end
end
