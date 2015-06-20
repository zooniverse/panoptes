require 'spec_helper'

RSpec.describe ClassificationsDumpWorker do
  let(:worker) { described_class.new }
  let(:project) { create(:project) }
  let!(:classifications) { create_list(:classification, 5, project: project) }

  describe "#perform" do
    it_behaves_like "dump worker", ClassificationDataMailerWorker, "project_classifications_export"
  end
end
