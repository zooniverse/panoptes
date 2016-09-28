require 'spec_helper'

RSpec.describe ProjectClassificationsCountWorker do
  let(:worker) { described_class.new }
  let!(:project) { create(:project) }

  describe "#perform" do

    it 'calls the project counter to update the project counts' do
      expect_any_instance_of(ProjectCounter).to receive(:classifications)
      expect_any_instance_of(Project)
        .to receive(:update_column)
        .with(:classifications_count, anything)
        .once
      worker.perform(project.id)
    end
  end
end
