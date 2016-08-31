require 'spec_helper'

RSpec.describe ProjectClassifiersCountWorker do
  let(:worker) { described_class.new }
  let(:project) { create(:project) }

  describe "#perform" do

    it 'calls the project counter to update the classifiers count' do
      expect_any_instance_of(ProjectCounter)
        .to receive(:volunteers)
      expect_any_instance_of(Project)
        .to receive(:update_column)
        .with(:classifiers_count, anything)
      worker.perform(project.id)
    end
  end
end
