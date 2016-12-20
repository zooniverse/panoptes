require 'spec_helper'

describe ResetProjectCountersWorker do
  let(:project)  { create :project, launch_date: Date.new(2015, 1, 1) }
  let(:workflow) { create :workflow_with_subjects, num_sets: 1, project: project }
  let(:subject)  { workflow.subjects.first }
  let(:user1)    { create :user }
  let(:user2)    { create :user }
  let(:sws)      { create :subject_workflow_status, subject: subject, workflow: workflow, classifications_count: 3 }
  let(:classification_attrs) do
    {
      created_at: project.launch_date - 1.week,
      project: project,
      workflow: workflow,
      subjects: [subject]
    }
  end

  before do
    sws
    create(:classification, classification_attrs.merge(user: user1))
    create(:classification, classification_attrs.merge(user: user2))
    create(:classification, classification_attrs.merge(user: user2, created_at: project.launch_date + 1.week))

    project.update_columns classifications_count: 3, classifiers_count: 3
    workflow.update_columns classifications_count: 3, retired_set_member_subjects_count: 2

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
    expect { project.reload }.to change { project.classifiers_count }.from(3).to(2)
  end

  it 'resets workflow classifications count' do
    described_class.new.perform(project.id)
    expect { workflow.reload }.to change { workflow.classifications_count }.from(3).to(1)
  end

  it 'resets retired subjects count' do
    described_class.new.perform(project.id)
    expect { workflow.reload }.to change { workflow.retired_subjects_count }.from(2).to(0)
  end

  it 'resets subject workflow counters' do
    described_class.new.perform(project.id)
    expect { sws.reload }.to change { sws.classifications_count }.from(3).to(1)
  end
end
