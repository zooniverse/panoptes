require 'spec_helper'

describe CsvDumps::DirectToS3 do
  let(:direct_to_s3) { described_class.new("full") }
  let(:adapter) { direct_to_s3.send(:storage_adapter) }

  let(:s3_path) { "email_exports/full_email_list.tar.gz" }
  let(:s3_opts) do
    {
      private: true,
      compressed: true,
      content_disposition: "attachment; filename=\"full_email_list.csv\""
    }
  end

  it "push the file to s3 the correct bucket location via a custom storage adapter" do
    expect(adapter).to receive(:stored_path)
                         .with("application/x-gzip", "email_exports")
                         .and_call_original
    expect(adapter).to receive(:put_file)
                         .with(s3_path, an_instance_of(String), s3_opts)

    direct_to_s3.put_file("/tmp/foobar")
  end
end
