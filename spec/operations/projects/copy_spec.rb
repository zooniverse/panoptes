require 'spec_helper'

describe Projects::Copy do
  let(:user) { create :user }
  let(:api_user) { ApiUser.new(user) }
  let(:operation) { described_class.with(api_user: api_user) }
  let(:project_to_copy) { create(:project, owner: user) }
  let(:params) { { project: project_to_copy } }
  let(:copied_project) { operation.run!(params) }

  it 'sets up the Project copier instance correctly' do
    copier_double = instance_double(ProjectCopier, copy: true)
    allow(ProjectCopier).to receive(:new).and_return(copier_double)
    copied_project
    expect(ProjectCopier).to have_received(:new).with(project_to_copy.id, user.id)
  end

  it 'calls the project copier copy method' do
    copier_double = instance_double(ProjectCopier)
    allow(copier_double).to receive(:copy)
    allow(ProjectCopier).to receive(:new).and_return(copier_double)
    copied_project
    expect(copier_double).to have_received(:copy)
  end

  it 'raises an error without project param' do
    expect {
      operation.run!(operation.run!(params.except(:project)))
    }.to raise_error(ActiveInteraction::InvalidInteractionError, 'Project is required')
  end

  it 'raises an error without api_user param' do
    operation = described_class.with({})
    expect {
      operation.run!(operation.run!(params))
    }.to raise_error(ActiveInteraction::InvalidInteractionError, "User can't be blank")
  end
end
