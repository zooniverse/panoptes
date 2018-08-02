require 'spec_helper'

describe ProjectCopyWorker do
  let(:worker) { described_class.new }
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:copier) { double(ProjectCopier, copied_project: true)}

  it { is_expected.to be_a Sidekiq::Worker }

  describe "#perform" do
    it "tells the project copier to copy the project" do
      expect(ProjectCopier)
        .to receive(:copy)
        .with(project.id, user.id)
      worker.perform(project.id, user.id)
    end

    it "should ignore unknown users and projects" do
      expect{
        worker.perform(-1, user.id)
      }.not_to raise_error

      expect{
        worker.perform(project.id, -1)
      }.not_to raise_error
    end
  end
end