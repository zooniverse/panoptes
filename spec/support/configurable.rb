RSpec.shared_examples "is configurable" do |prefix|
  describe '::load_configuration' do
    before(:each) do
      allow(described_class).to receive(:configuration).and_return({host: "http://test.example.com",
        user: user.id.to_s,
        application: application.id.to_s})
    end

    context 'configuration in ENV variables' do
      before(:each) do
        ENV["#{prefix}_API_HOST"] = 'http://example.com'
        ENV["#{prefix}_API_USER"] = '1'
        ENV["#{prefix}_API_APPLICATION"] = '1'
        described_class.load_configuration
      end

      after(:each) do
        ENV.delete("#{prefix}_API_HOST")
        ENV.delete("#{prefix}_API_USER")
        ENV.delete("#{prefix}_API_APPLICATION")
      end

      it "should set host to #{prefix}_API_HOST var" do
        expect(described_class.host).to eq('http://example.com')
      end

      it "should set user_id to #{prefix}_API_USER var" do
        expect(described_class.user_id).to eq(1)
      end

      it "should set application_id to #{prefix}_API_APPLICATION var" do
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

    it "should try to load the file at config/#{prefix.downcase}_api.yml" do
      expect(File).to receive(:read).with(Rails.root.join "config/#{prefix.downcase}_api.yml")
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
end
