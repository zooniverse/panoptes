require "spec_helper"

describe Cassandra::Classification, type: :model do

  subject { described_class.new }

  after(:each) do
    Cassandra::Classification.delete_all
  end

  describe "::from_ar_model" do
    let(:ar_classification) { create(:classification) }

    before(:each) do
      described_class.from_ar_model(ar_classification)
    end

    it 'should create and save cassandra classifications for each subject' do
      expect(Cassandra::Classification.count).to eq(ar_classification.subject_ids.length)
    end

    it "should have the same annotations" do
      annotations = JSON.parse(Cassandra::Classification.first.annotations)
      expect(annotations).to eq(ar_classification.annotations)
    end
  end

  describe "::table_name" do
    it "should be classifications" do
      expect(described_class.table_name).to eq(:classifications)
    end
  end

  describe "#workflow_version=" do
    it "should strip minor version number" do
      subject.workflow_version = "11.14"
      expect(subject.workflow_version).to eq(11)
    end
  end

  describe "#annotations=" do
    it 'should convert hash into stringified JSON' do
      subject.annotations = [{"test" => "anno"}]
      expect(subject.annotations).to eq("[{\"test\":\"anno\"}]")
    end

  end

  describe "#metadata" do
    it 'should convert hash into stringified JSON' do
      subject.metadata = {"test" => "meta"}
      expect(subject.metadata).to eq("{\"test\":\"meta\"}")
    end
  end

  describe "#save_subject" do
    it "should save a 'subject record'" do
      attrs = {
        project_id: 1,
        workflow_id: 1,
        subject_id: 1,
        workflow_version: 10
      }
      classification = described_class.new(attrs)
      subject = classification.save_subject
      aggregate_failures "saved subject" do
        expect(subject).to be_persisted
        expect(subject.attributes.with_indifferent_access).to include(attrs)
      end
    end
  end
end
