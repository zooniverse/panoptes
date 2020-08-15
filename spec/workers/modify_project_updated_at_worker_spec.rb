  require 'spec_helper'

  describe ModifyProjectUpdatedAtWorker do
    let(:worker) { described_class.new }
    let(:project) { create :project }

    describe "project touch timestamp" do
        before do
          allow(Project).to receive(:find).and_return(project)
        end
    
        it "should touch the project timestamp on update" do
          expect(project).to receive(:touch).once
          worker.perform(project)
        end
      end
  end