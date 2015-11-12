require 'spec_helper'

describe ResetProjectCountersWorker do
  let(:project)  { create :project, launch_date: Date.new(2015, 1, 1) }
  let(:workflow) { create :workflow, project: project }
  let(:subject)  { create :subject, project: project }
  let(:user1)    { create :user }
  let(:user2)    { create :user }
  let(:swc)      { create :subject_workflow_count, subject: subject, workflow: workflow, classifications_count: 3 }

  before do
    classification1 = create(:classification, user: user1, created_at: project.launch_date - 1.week, project: project, workflow: workflow, subjects: [subject])
    classification2 = create(:classification, user: user2, created_at: project.launch_date - 1.week, project: project, workflow: workflow, subjects: [subject])
    classification3 = create(:classification, user: user2, created_at: project.launch_date + 1.week, project: project, workflow: workflow, subjects: [subject])

    project.update_columns classifications_count: 3, classifiers_count: 2
    workflow.update_columns classifications_count: 3

    create :user_project_preference, user: user1, project: project
    create :user_project_preference, user: user2, project: project

    project.reload
    workflow.reload
  end

  it 'resets classifications count' do
    described_class.new.perform(project.id)
    expect { project.reload }.to change { project.classifications_count }.from(3).to(1)
  end

  it 'resets classifiers count' do
    described_class.new.perform(project.id)
    expect { project.reload }.to change { project.classifiers_count }.from(2).to(1)
  end

  it 'resets workflow classifications count' do
    described_class.new.perform(project.id)
    expect { workflow.reload }.to change { workflow.classifications_count }.from(3).to(1)
  end

  it 'resets subject workflow counters' do
    swc.save
    described_class.new.perform(project.id)
    expect { swc.reload }.to change { swc.classifications_count }.from(3).to(1)
  end

end
