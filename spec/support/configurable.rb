RSpec.shared_examples "is configurable" do |prefix|
  describe '::load_configuration' do
    before(:each) do
      allow(described_class).to receive(:config_from_file).and_return({})
      allow(described_class).to receive(:env_vars).and_return({})
    end

    context 'configuration in ENV variables' do
      before(:each) do
        allow(described_class).to receive(:env_vars).and_return({
          "#{prefix}_API_HOST" => 'http://example.com',
          "#{prefix}_API_USER" => '1',
          "#{prefix}_API_APPLICATION" => '1',
        })
        described_class.load_configuration
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
        allow(described_class).to receive(:config_from_file).and_return({
          host: "http://test.example.com",
          user: user.id.to_s,
          application: application.id.to_s
        })
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

  describe "::config_from_file" do
    before(:each) do
      described_class.instance_variable_set(:@config_from_file, nil)
    end

    it "should try to load the file at config/#{prefix.downcase}_api.yml" do
      expect(File).to receive(:read).with(Rails.root.join "config/#{prefix.downcase}_api.yml")
      described_class.config_from_file
    end

    it 'should retun the file section for the current rails environment' do
      allow(File).to receive(:read).and_return(
        "test:\n  host: example.coffee\ndevelopment:\n  host: example.sucks"
      )
      expect(described_class.config_from_file).to eq({ host: 'example.coffee' })
    end

    it 'should memoize the results' do
      described_class.config_from_file
      expect(File).to_not receive(:read)
      described_class.config_from_file
    end
  end
end
