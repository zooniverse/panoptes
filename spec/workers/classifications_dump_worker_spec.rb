require 'spec_helper'

RSpec.describe ClassificationsDumpWorker do
  let(:worker) { described_class.new }
  let(:project) { create(:project) }
  let!(:classifications) { create_list(:classification, 5, project: project) }
  let(:another_project) { create(:project) }
  let!(:other_project_classifications) { create(:classification, project: another_project) }

  describe "#perform" do
    context "when the project id doesn't correspond to a project" do
      before(:each) do
        allow(Project).to receive(:find).and_return(nil)
      end

      it "should not open a csv file" do
        expect(CSV).to_not receive(:open)
        worker.perform(another_project.id)
      end

      it "should not push a file to s3" do
        expect(worker).to_not receive(:write_to_s3)
        worker.perform(another_project.id)
      end

      it "should not queue a worker to send an email" do
        expect(ClassificationDataMailerWorker).to_not receive(:perform_async)
        worker.perform(another_project.id)
      end
    end

    context "when the project exists" do
      let(:project_file_name) do
        "#{project.owner.display_name}_#{project.display_name.downcase.gsub(/\s/, "_")}.csv"
      end

      let(:temp_file_path) { "#{Rails.root}/tmp/#{project_file_name}" }

      it "should create a csv file with the correct number of entries" do
        expect_any_instance_of(CSV).to receive(:<<).exactly(6).times
        worker.perform(project.id)
      end

      it "should create a linked media resource" do
        expect(Medium).to receive(:create!).and_call_original
        worker.perform(project.id)
      end

      it "should not fail to create a linked media resource" do
        expect { worker.perform(project.id) }.to_not raise_error
      end

      it "push the file to s3" do
        expect(worker).to receive(:write_to_s3).once
        worker.perform(project.id)
      end

      it "should clean up the file after sending to s3" do
        expect(FileUtils).to receive(:rm).with(temp_file_path)
        worker.perform(project.id)
      end

      it "should queue a worker to send an email" do
        expect(ClassificationDataMailerWorker).to receive(:perform_async).with(project.id,
                                                                               anything,
                                                                               [project.owner.email])
        worker.perform(project.id)
      end
    end

    context "when a medium id is also provided" do
      let(:receivers) { create_list(:user, 2) }
      let(:medium) do
        create(:medium,
               metadata: { "recipients" => receivers.map(&:id) },
               linked: project,
               content_type: "text/csv",
               type: "project_classifications_export")
      end

      it 'should update the path on the object' do
        worker.perform(project.id, medium.id)
        medium.reload
        expect(medium.path_opts).to match_array([project.owner.display_name.gsub(/\s/, "_"),
                                                 project.display_name.downcase.gsub(/\s/, "_")])
      end

      it 'should set the medium to private' do
        worker.perform(project.id, medium.id)
        medium.reload
        expect(medium.private).to be true
      end

      it 'should email the users in the recipients hash' do
        expect(ClassificationDataMailerWorker).to receive(:perform_async).with(anything, anything, receivers.map(&:email))
        worker.perform(project.id, medium.id)
      end
    end
  end
end
