RSpec.shared_examples "filter by display_name" do
  before(:each) do
    get :index, index_options
  end

  describe "filter by display_name" do
    let(:index_options) { { display_name: resource.display_name + '*'} }

    it "should respond with 1 item" do
      expect(json_response[api_resource_name].length).to eq(1)
    end

    it "should respond with the correct item" do
      expect(json_response[api_resource_name][0]['display_name']).to eq(resource.display_name)
    end
  end

  describe "filter by case insensitive display_name" do
    let(:index_options) { { display_name: resource.display_name.upcase + '*'} }

    it "should respond with 1 item" do
      expect(json_response[api_resource_name].length).to eq(1)
    end

    it "should respond with the correct item" do
      expect(json_response[api_resource_name][0]['display_name']).to eq(resource.display_name)
    end
  end

  describe 'filter by wildcard match display_name' do
     let(:index_options) { { display_name: resource.display_name.upcase[0..-3] + '*'} }

    it "should respond with the correct item" do
      expect(json_response[api_resource_name].map{ |r| r['display_name']}).to include(resource.display_name)
    end
  end
end
