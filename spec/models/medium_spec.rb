require 'spec_helper'

RSpec.describe Medium, :type => :model do
  let(:medium) { build(:medium, src: nil) }

  it 'should not be private by default' do
    m = Medium.new
    expect(m.private).to be false
  end

  it 'should not be externally linked by default' do
    m = Medium.new
    expect(m.external_link).to be false
  end

  describe "#content_type" do
    it 'should not be valid with an empty content_type' do
      m = build(:medium, content_type: "")
      expect(m).to_not be_valid
    end

    context 'when non-export medium types' do
      it 'is valid with allowed content_types' do
        aggregate_failures 'content types' do
          limited_list_of_allowed_mime_types = %w(
            image/jpeg
            image/png
            image/gif
            image/svg+xml
            audio/mpeg
            audio/mp3
            audio/mp4
            audio/x-m4a
            text/plain
            text/csv
            video/mp4
            application/pdf
            application/json
          )
          limited_list_of_allowed_mime_types.each do |content_type|
            m = build(:medium, content_type: content_type)
            expect(m).to be_valid
          end
        end
      end

      it 'does not allow invalid non-allowlisted content_types' do
        aggregate_failures 'content types' do
          limited_list_of_unallowed_mime_types = %w[
            text/html
            text/css
            application/javascript
            test/html-json
          ]
          limited_list_of_unallowed_mime_types.each do |content_type|
            m = build(:medium, content_type: content_type)
            expect(m).not_to be_valid
          end
        end
      end
    end

    context "export medium types" do
      let(:export_medium) do
        build(:medium, type: "project_test_export")
      end

      it 'should be valid for csv content_types' do
        export_medium.content_type = "text/csv"
        expect(export_medium).to be_valid
      end

      it 'should not be valid non-csv content_types' do
        export_medium.content_type = "text/html"
        expect(export_medium).not_to be_valid
      end
    end
  end

  context "when the src field is blank" do
    before(:each) do
      allow(MediaStorage).to receive(:stored_path).and_return(nil)
    end

    it 'should not be valid without a src' do
      expect(medium).to be_invalid
    end

    it 'should have a useful error message' do
      medium.valid?
      expect(medium.errors[:src]).to include("can't be blank")
    end
  end

  describe "#create_path" do
    context "when not externally linked" do

      it 'should create src path when saved' do
        medium.save!
        expect(medium.src).to be_a(String)
      end

      it 'should call MediaStorage with the content_type, type, and path_opts' do
        expect(MediaStorage).to receive(:stored_path)
          .with(medium.content_type, medium.type, *medium.path_opts)
        medium.create_path
      end
    end

    context "when externally linked" do
      let(:medium) { create(:medium, external_link: true, src: nil) }
      it 'should not create a src path' do
        medium.save!
        expect(medium.src).to be_nil
      end
    end
  end

  describe "#put_url" do
    context "when not externally linked" do
      it 'should call MediaStorage with the src and other attributes' do
        expect(MediaStorage).to receive(:put_path).with(medium.src, medium.attributes)
        medium.put_url
      end

      it 'should pass attributes as hash with indifferent access' do
        expect(MediaStorage).to receive(:put_path)
          .with(anything, be_a(HashWithIndifferentAccess))
        medium.put_url
      end

      it 'should pass opts to MediaStorage' do
        expect(MediaStorage).to receive(:put_path).with(anything, hash_including('foo' => 'bar'))
        medium.put_url(foo: 'bar')
      end
    end

    context "when externally linked" do
      let(:medium) { create(:medium, external_link: true) }
      it 'should return the src' do
        expect(medium.put_url).to eq(medium.src)
      end
    end
  end

  describe "#get_url" do
    context "when not externally linked" do
      it 'should call MediaStorage with the src and other attributes' do
        expect(MediaStorage).to receive(:get_path).with(medium.src, medium.attributes)
        medium.get_url
      end

      it 'should pass attributes as hash with indifferent access' do
        expect(MediaStorage).to receive(:get_path)
          .with(anything, be_a(HashWithIndifferentAccess))
        medium.get_url
      end

      it 'should pass opts to MediaStorage' do
        expect(MediaStorage).to receive(:get_path).with(anything, hash_including('foo' => 'bar'))
        medium.get_url(foo: 'bar')
      end
    end

    context "when externally linked" do
      let(:medium) { create(:medium, external_link: true) }
      it 'should return the src' do
        expect(medium.get_url).to eq(medium.src)
      end
    end
  end

  describe "#put_file" do

    let(:file_path) { "#{Rails.root}/tmp/project_x_dump.csv" }
    let(:media_storage_put_file_params) { [ medium.src, file_path, medium.attributes ]}

    it 'should call MediaStorage with the src and other attributes' do
      expect(MediaStorage).to receive(:put_file).with(*media_storage_put_file_params)
      medium.put_file(file_path)
    end

    it 'should pass attributes as hash with indifferent access' do
      expect(MediaStorage).to receive(:put_file)
        .with(anything, anything, be_a(HashWithIndifferentAccess))
      medium.put_file(file_path)
    end

    context "when passed a blank file_path" do
      let!(:file_path) { "" }

      it 'should raise and error' do
        expect {
          medium.put_file(file_path)
        }.to raise_error(Medium::MissingPutFilePath, "Must specify a file_path to store")
      end
    end
  end

  describe '#put_file_with_retry' do
    let(:file_path) { Rails.root.join('/tmp/project_x_dump.csv') }
    let(:media_storage_put_file_params) do
      [medium.src, file_path, medium.attributes]
    end

    it 'calls MediaStorage put_file with the src and other attributes' do
      allow(MediaStorage).to receive(:put_file)
      medium.put_file_with_retry(file_path)
      expect(MediaStorage).to have_received(:put_file).with(*media_storage_put_file_params)
    end

    it 'retries the correct number of times' do
      allow(MediaStorage).to receive(:put_file).and_raise(Faraday::ConnectionFailed, 'Connection reset by peer')
      medium.put_file_with_retry(file_path)
    rescue Faraday::ConnectionFailed
      expect(MediaStorage).to have_received(:put_file).with(*media_storage_put_file_params).exactly(5).times
    end

    it 'allows the retry number to be modified at runtime' do
      allow(MediaStorage).to receive(:put_file).and_raise(Faraday::ConnectionFailed, 'Connection reset by peer')
      medium.put_file_with_retry(file_path, {}, 2)
    rescue Faraday::ConnectionFailed
      expect(MediaStorage).to have_received(:put_file).with(*media_storage_put_file_params).twice
    end

    it 'does not retry if put_file raises MissingPutFilePath' do
      allow(medium).to receive(:put_file).and_call_original
      medium.put_file_with_retry('')
    rescue Medium::MissingPutFilePath
      expect(medium).to have_received(:put_file).once
    end
  end

  describe "#locations" do
    let(:project) { create(:project) }
    context "when type is one of project_avatar, user_avatar, or project_background" do
      it 'should return the href the resource can be found at' do
        medium = create(:medium, type: "project_avatar", linked: project)
        expect(medium.location).to match(/\/projects\/[0-9]+\/avatar/)
      end
    end

    context "when type is one of project_classifications_exports or project_attached_image" do
      it 'should return the href the resource can be found at' do
        medium = create(:medium, type: "project_attached_image", linked: project)
        expect(medium.location).to match(/\/projects\/[0-9]+\/attached_images\/[0-9]+/)
      end
    end

   context "when type is one of workflow_classifications_export" do
      let(:workflow) { create(:workflow) }
      it 'should return the href the resource can be found at' do
        medium = create(:medium, type: "workflow_classifications_export", linked: workflow, content_type: "text/csv")
        expect(medium.location).to match(/\/workflows\/[0-9]+\/classifications_export/)
      end
    end
  end

  describe "before destroy callbacks" do
    it 'should queue a worker to remove the attached files' do
      medium = create(:medium)
      aggregate_failures do
        expect(medium).to receive(:queue_medium_removal).and_call_original
        expect(MediumRemovalWorker).to receive(:perform_async).with(medium.src, HashWithIndifferentAccess)
      end
      medium.destroy
    end

    it 'should not queue a worker if the src is external' do
      medium.external_link = true
      expect(medium).not_to receive(:queue_medium_removal)
      expect(MediumRemovalWorker).not_to receive(:perform_async)
      medium.destroy
    end
  end
end
