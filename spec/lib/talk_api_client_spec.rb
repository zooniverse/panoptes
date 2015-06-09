require 'spec_helper'

RSpec.describe TalkApiClient do
  let(:user) { create(:admin_user)}

  let(:application) { create(:application, owner: user) }

  describe '::load_configuration' do
    before(:each) do
      allow(described_class).to receive(:configuration).and_return({host: "http://test.example.com",
                                                                    user: user.id.to_s,
                                                                    application: application.id.to_s})
    end

    context 'configuration in ENV variables' do
      before(:each) do
        ENV['TALK_API_HOST'] = 'http://example.com'
        ENV['TALK_API_USER'] = '1'
        ENV['TALK_API_APPLICATION'] = '1'
        described_class.load_configuration
      end

      after(:each) do
        ENV.delete('TALK_API_HOST')
        ENV.delete('TALK_API_USER')
        ENV.delete('TALK_API_APPLICATION')
      end

      it 'should set host to TALK_API_HOST var' do
        expect(described_class.host).to eq('http://example.com')
      end

      it 'should set user_id to TALK_API_USER var' do
        expect(described_class.user_id).to eq(1)
      end

      it 'should set application_id to TALK_API_APPLICATION var' do
        expect(described_class.application_id).to eq(1)
      end
    end

    context 'configuration in file' do
      before(:each) do
        described_class.load_configuration
      end

      it 'should set host to configuration host' do
        expect(described_class.host).to eq('http://test.example.com')
      end

      it 'should set user_id to configuration user' do
        expect(described_class.user_id).to eq(user.id)
      end

      it 'should set application_id to configuration application' do
        expect(described_class.application_id).to eq(application.id)
      end
    end
  end

  describe "::configuration" do
    before(:each) do
      described_class.instance_variable_set(:@configuration, nil)
    end

    it 'should try to load the file at config/talk_api.yml' do
      expect(File).to receive(:read).with(Rails.root.join 'config/talk_api.yml')
      described_class.configuration
    end

    it 'should retun the configuration for the current rails environment' do
      expect(YAML).to receive(:load).and_return({"test" => {host: "example.coffee"},
                                                 "development" => {host: "example.sucks"}})
      expect(described_class.configuration).to eq({host: "example.coffee"})
    end

    it 'should memoize the results' do
      described_class.configuration
      expect(File).to_not receive(:read)
      described_class.configuration
    end
  end

  it 'raise an error when no host is configured' do
    described_class.host = nil
    expect{described_class.new}.to raise_error(TalkApiClient::NoTalkHostError, "A talk instance has not been configured for test environment")
  end

  context "instance methods" do
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get('/error') do env
          [404,
           {'Content-Type' => 'application/vnd.api+json'},
           {errors: [message: "Not Found"]}.to_json
          ]
        end
        stub.get('/') do |env|
          [200,
           {'Content-Type' => 'application/vnd.api+json'},
           {roles: { href: '/roles', type: 'roles'}}.to_json]
        end
      end
    end

    before(:each) do
      allow(described_class).to receive(:configuration).and_return({host: "http://test.example.com",
                                                                    user: user.id.to_s,
                                                                    application: application.id.to_s})
      described_class.load_configuration
    end

    describe "#create_token" do
      subject { described_class.new([:test, stubs]).token.attributes }

      it { is_expected.to include("resource_owner_id" => user.id) }
      it { is_expected.to include("application_id" => application.id) }
      it { is_expected.to include("expires_in" => 1.day) }
    end

    describe "#initial_reqest" do
      subject { described_class.new([:test, stubs]) }

      it 'should add resources to the resources hash' do
        expect(subject.instance_variable_get(:@resources)).to include('roles')
      end

      it 'should create a resource class for the hash' do
        expect(subject.instance_variable_get(:@resources)['roles']).to be_a(TalkApiClient::JSONAPIResource)
      end
    end

    describe "#request" do
      subject { described_class.new([:test, stubs]) }

      it 'should make a request with the connection' do
        expect(subject.connection).to receive(:send).with('get', '/')
        subject.request('get', '/')
      end

      it 'should set the token in the request' do
        subject.request('get', '/') do |req|
          expect(req.headers['Authorization']).to match(/Bearer [A-z0-9]+/)
        end
      end

      it 'should raise an error on failure' do
        expect{subject.request('get', '/error')}.to raise_error
      end
    end

    describe "#method_missing" do
      subject { described_class.new([:test, stubs]) }

      it 'should proxy the resources hash' do
        expect(subject.roles).to be_a(TalkApiClient::JSONAPIResource)
      end

      it 'should raise an error if no resource is known' do
        expect{ subject.boards }.to raise_error
      end
    end

    describe "TalkApiClient::JSONAPIResource" do
      let(:conn_instance) { described_class.new([:test, stubs])}

      describe "#create" do
        it 'should send a POST request with a JSON body' do
          expect(conn_instance).to receive(:request).with('post', '/roles') do |*args, &block|
            struct = Struct.new(:body).new
            block.call(struct)
            expect(struct.body).to eq({roles: {role: "admin"}}.to_json)
          end
          conn_instance.roles.create(role: "admin")
        end
      end
    end
  end
end
