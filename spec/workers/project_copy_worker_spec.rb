require 'spec_helper'

describe ProjectCopyWorker do
  let(:worker) { described_class.new }
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:project_copier_double) { instance_double(ProjectCopier) }

  it { is_expected.to be_a Sidekiq::Worker }

  describe '#perform' do
    before do
      allow(project_copier_double).to receive(:copy)
      allow(ProjectCopier).to receive(:new).and_return(project_copier_double)
    end

    it 'uses the project copier correctly' do
      worker.perform(project.id, user.id)
      expect(ProjectCopier).to have_received(:new).with(project.id, user.id)
    end

    it 'uses the project copier to copy the project' do
      worker.perform(project.id, user.id)
      expect(project_copier_double).to have_received(:copy)
    end

    it 'ignores unknown users' do
      expect{
        worker.perform(-1, user.id)
      }.not_to raise_error
    end

    it 'ignores unknown projects' do
      expect{
        worker.perform(project.id, -1)
      }.not_to raise_error
    end
  end
end
