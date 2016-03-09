require 'spec_helper'

UUIDv4Regex = /[a-f0-9]{8}\-[a-f0-9]{4}\-4[a-f0-9]{3}\-(8|9|a|b)[a-f0-9]{3}\-[a-f0-9]{12}/

RSpec.describe MediaStorage::AwsAdapter do
  let(:prefix) { "panoptes_staging" }
  let(:bucket) { "media.zooniverse.org" }
  let(:adapter) do
    described_class.new(prefix: prefix, bucket: bucket, access_key_id: 'fake', secret_access_key: 'keys')
  end

  context 'when keys are passed to the initializer' do
    it 'should set the aws config ' do
      expect(AWS).to receive(:config).with(access_key_id: 'fake', secret_access_key: 'keys')
      described_class.new(access_key_id: 'fake', secret_access_key: 'keys')
    end
  end

  context 'when no prefix is passed to the initializer' do
    it 'should set the prefix to the Rails.env' do
      adapter = described_class.new(access_key_id: 'fake', secret_access_key: 'keys')
      expect(adapter.prefix).to eq("test")
    end
  end

  describe "#stored_path" do
    subject { adapter.stored_path('image/jpeg', 'subject_location')}

    it { is_expected.to be_a(String) }
    it { is_expected.to match(/#{prefix}/)}
    it { is_expected.to match(/subject_location/)}
    it { is_expected.to match(/\.jpeg/)}
    it { is_expected.to match(UUIDv4Regex)}

    context "with an extract path prefix" do
      subject { adapter.stored_path('image/jpeg', 'subject_location', "extra", "prefixes")}

      it { is_expected.to match(/extra\/prefixes/)}
    end

    context "with an application/x-gzip content-type" do
      subject { adapter.stored_path('application/x-gzip', 'subject_location')}

      it { is_expected.to match(/\.tar\.gz/)}
    end
  end

  shared_examples "signed s3 url" do
    it { is_expected.to match(/\A#{URI::regexp}\z/) }
    it { is_expected.to match(/#{bucket}/) }
    it { is_expected.to match(/Expires=[0-9]+&Signature=[%A-z0-9]+/) }
  end

  describe "#get_path" do
    context "when the path is public" do
      subject{ adapter.get_path("media.zooniverse.org/subject_locations/name.jpg") }

      it { is_expected.to match(/\A#{URI::regexp}\z/) }
    end

    context "when the path is private" do
      subject{ adapter.get_path("media.zooniverse.org/subject_locations/name.jpg", private: true) }
      it_behaves_like "signed s3 url"
    end
  end

  describe "#put_path" do
    subject{ adapter.put_path("media.zooniverse.org/subject_locations/name.jpg") }

    it_behaves_like "signed s3 url"
  end

  describe "#delete_file" do
    let(:obj_double) { double(write: true) }

    before(:each) do
      allow(adapter).to receive(:object).and_return(obj_double)
    end

    it 'should call #delete on the s3 object' do
      expect(obj_double).to receive(:delete)
      adapter.delete_file("blash.txt")
    end
  end

  describe "#put_file" do
    let(:obj_double) { double(write: true) }
    let(:file_path) { "a_path.txt" }
    let(:content_type) { "text/csv" }

    before(:each) do
      allow(adapter).to receive(:object).and_return(obj_double)
    end

    context "when opts[:private] is true" do
      it 'should call write with the content_type, file, and private acl' do
        expect(obj_double).to receive(:write).with(file: file_path,
          content_type: content_type,
          acl: 'private')
        adapter.put_file("src", file_path, content_type: content_type, private: true)
      end
    end

    context "when opts[:private] is false" do
      it 'should call write with the content_type, file, and public-read acl' do
        expect(obj_double).to receive(:write).with(file: file_path,
          content_type: content_type,
          acl: 'public-read')
        adapter.put_file("src", file_path, content_type: content_type, private: false)
      end
    end

    context "when opts[:compressed] is true" do
      it 'should call write wtih the content_encoding set to gzip' do
        expect(obj_double).to receive(:write).with(file: file_path,
          content_type: content_type,
          acl: 'public-read',
          content_encoding: 'gzip')
        adapter.put_file("src", file_path, content_type: content_type, private: false, compressed: true)
      end
    end

    context "when opts[:content_disposition] is set" do
      let(:disposition) { "attachment; filename='fname.ext'" }

      it 'should call write with the content_disposition set' do
        expect(obj_double)
          .to receive(:write)
          .with(
            file: file_path,
            content_type: content_type,
            acl: 'public-read',
            content_disposition: disposition
          )
        put_opts = { content_type: content_type, content_disposition: disposition }
        adapter.put_file("src", file_path, put_opts)
      end
    end
  end

  context "when missing an s3 object path" do
    it 'should raise an error' do
      error_message = "A storage path must be specified."
      expect do
        adapter.send(:object, nil)
      end.to raise_error(MediaStorage::AbstractAdapter::EmptyPathError, error_message)
    end
  end
end
