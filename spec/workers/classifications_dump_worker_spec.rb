require 'spec_helper'

RSpec.describe ClassificationsDumpWorker do
  let(:worker) { described_class.new }
  let(:project) { create(:project) }
  let!(:classifications) { create_list(:classification, 5, project: project) }
  let(:another_project) { create(:project) }
  let!(:other_project_classifications) { create(:classification, project: another_project) }

  describe "#perform" do

    before(:each) do
      AWS.stub!
    end

    context "when the project id doesn't correspond to a project" do

      it "should not do anything" do
        allow(Project).to receive(:find).and_return(nil)
        expect(Tempfile).to_not receive(:open)
        worker.perform(another_project.id)
      end
    end

    context "when the project exists" do

      let(:project_file_name) { "#{project.name.downcase.gsub(/\s/, "_")}.csv" }
      let(:temp_file_path) { "#{Rails.root}/tmp/#{project_file_name}" }

      it "should create a csv file with the correct number of entries" do
        expect_any_instance_of(CSV).to receive(:<<).exactly(6).times
        worker.perform(project.id)
      end

      it "push the file to s3" do
        expect(worker).to receive(:write_to_s3).once
        worker.perform(project.id)
      end

      it "should clean up the file after sending to s3" do
        expect(FileUtils).to receive(:rm).with(temp_file_path)
        worker.perform(project.id)
      end
    end
  end
end
