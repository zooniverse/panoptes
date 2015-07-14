RSpec.shared_examples "dump worker" do |mailer_class, dump_type|
  let(:another_project) { create(:project) }

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
      expect(mailer_class).to_not receive(:perform_async)
      worker.perform(another_project.id)
    end
  end

  context "when the project exists" do
    let(:project_file_name) do
      "#{dump_type}_#{project.owner.login}_#{project.display_name.downcase.gsub(/\s/, "_")}.csv"
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
      expect(FileUtils).to receive(:rm).twice.and_call_original
      worker.perform(project.id)
    end

    it "should queue a worker to send an email" do
      expect(mailer_class).to receive(:perform_async).with(project.id,
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
             content_type: "application/x-gzip",
             type: dump_type)
    end

    it 'should update the path on the object' do
      worker.perform(project.id, medium.id)
      medium.reload
      expect(medium.path_opts).to match_array([dump_type,
                                               project.owner.login.gsub(/\s/, "_"),
                                               project.display_name.downcase.gsub(/\s/, "_")])
    end

    it 'should set the medium to private' do
      worker.perform(project.id, medium.id)
      medium.reload
      expect(medium.private).to be true
    end

    it 'should email the users in the recipients hash' do
      expect(mailer_class).to receive(:perform_async).with(anything, anything, receivers.map(&:email))
      worker.perform(project.id, medium.id)
    end
  end
end
