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

    it "should create a csv file with the correct number of entries" do
      expect_any_instance_of(CSV).to receive(:<<).exactly(num_entries).times
      worker.perform(project.id)
    end

    it "should create a linked media resource" do
      expect(Medium).to receive(:create!).and_call_original
      worker.perform(project.id)
    end

    it "should not fail to create a linked media resource" do
      expect { worker.perform(project.id) }.to_not raise_error
    end

    it "should compress the csv file" do
      expect(worker).to receive(:to_gzip).and_call_original
      worker.perform(project.id)
    end

    it "push the file to s3" do
      expect(worker).to receive(:write_to_s3).once
      worker.perform(project.id)
    end

    it "should clean up the file after sending to s3" do
      expect(worker).to receive(:remove_tempfile).twice.and_call_original
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
    let(:metadata) { { "recipients" => receivers.map(&:id) } }
    let(:medium) do
      create(:medium,
             metadata: metadata,
             linked: project,
             content_type: "text/csv",
             type: dump_type)
    end

    it 'should update the path on the object' do
      worker.perform(project.id, medium.id)
      medium.reload
      expect(medium.path_opts).to match_array([dump_type, project.id.to_s])
    end

    it 'should set the medium to private' do
      worker.perform(project.id, medium.id)
      medium.reload
      expect(medium.private).to be true
    end

    it 'should update the medium content_type to csv' do
      medium.update_column(:content_type, "text/html")
      worker.perform(project.id, medium.id)
      medium.reload
      expect(medium.content_type).to eq("text/csv")
    end

    it 'should update the medium content_disposition' do
      worker.perform(project.id, medium.id)
      medium.reload
      name = project.slug.split("/")[1]
      type = medium.type.match(/\Aproject_(\w+)_export\z/)[1]
      ext = MIME::Types[medium.content_type].first.extensions.first
      file_name = "#{name}-#{type}.#{ext}"
      expect(medium.content_disposition).to eq("attachment; filename=\"#{file_name}\"")
    end

    it "should set the medium state to ready" do
      worker.perform(project.id, medium.id)
      medium.reload
      expect(medium.metadata).to include("state" => "ready")
    end

    it 'should email the users in the recipients hash' do
      expect(mailer_class).to receive(:perform_async)
        .with(anything, anything, array_including(receivers.map(&:email)))
      worker.perform(project.id, medium.id)
    end

    context "simulating a failed dump" do

      it "should set the medium state to creating" do
        allow(worker).to receive(:set_ready_state)
        worker.perform(project.id, medium.id)
        medium.reload
        expect(medium.metadata).to include("state" => "creating")
      end
    end
  end
end
