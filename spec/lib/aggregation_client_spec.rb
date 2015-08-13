require "spec_helper"

RSpec.describe AggregationClient do
  let(:user) { create(:admin_user)}
  let(:project) { create(:project) }
  let(:medium) { create(:medium) }

  let(:application) { create(:application, owner: user) }

  let(:stubs) do
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post('/') do |env|
        [200,
          {'Content-Type' => 'application/json'},
          {status: 'queued'}.to_json]
      end
    end
  end

  it_behaves_like "is configurable", "AGGREGATION"

  context "instance methods" do
    before(:each) do
      allow(described_class).to receive(:configuration).and_return({host: "http://test.example.com",
        user: user.id.to_s,
        application: application.id.to_s})
      described_class.load_configuration
    end

    describe "#generate_token" do
      subject{ described_class.new([:test, stubs]).generate_token.attributes }

      it { is_expected.to include("resource_owner_id" => user.id) }
      it { is_expected.to include("application_id" => application.id) }
      it { is_expected.to include("expires_in" => 1.day) }
    end

    describe "#aggregate!" do
      subject{ described_class.new([:test, stubs]) }

      it 'should make a request with the connection' do
        expect(subject.connection).to receive(:post).with('/')
        subject.aggregate(project, medium)
      end
    end

    describe "#body" do
      subject{ described_class.new([:test, stubs]).body(project, medium) }

      it { is_expected.to include(:token, medium_href: medium.location,
        metadata: medium.metadata, project_id: project.id) }
    end
  end
end
