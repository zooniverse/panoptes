require 'spec_helper'

describe "Upon classifying", type: :request, sidekiq: :inline do
  it 'should record the first project a user contributed to' do
    project1 = create(:full_project)
    project2 = create(:full_project)
    user = create(:user)

    as(user) do |api|
      metadata = {workflow_version: '1.1', user_language: 'en', user_agent: '', started_at: '', finished_at: ''}

      api.post '/api/classifications', classifications: {annotations: [{}], metadata: metadata, completed: true, links: {project: project1.id, workflow: project1.workflows.first.id, subjects: [project1.subjects.first.id]}}
      api.post '/api/classifications', classifications: {annotations: [{}], metadata: metadata, completed: true, links: {project: project2.id, workflow: project2.workflows.first.id, subjects: [project2.subjects.first.id]}}

      expect(user.reload.project_id).to eq(project1.id)
    end
  end

end
