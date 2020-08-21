require 'spec_helper'

describe TouchProjectWorker do
  let(:worker) { described_class.new }
  let(:project) { create :project }

  it 'touches the project timestamp on update' do
    allow(Project).to receive(:find).and_return(project)
    allow(project).to receive(:touch)
    worker.perform(project.id)
    expect(project).to have_received(:touch).once
  end
end
