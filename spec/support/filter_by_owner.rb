RSpec.shared_examples "filters by owner" do
  let(:index_options) do
    { owner: owner.login }
  end
  let(:expected_count) { owner_resources.count }

  before do
    resource
    get :index, params: index_options
  end

  it "should respond with the correct number of items" do
    expect(json_response[api_resource_name].length).to eq(expected_count)
  end

  it "should respond with the correct item" do
    owner_id = json_response[api_resource_name][0]['links']['owner']['id']
    expect(owner_id).to eq(resource.owner.id.to_s)
  end

  context "when the owner name has a different case to the identity group" do
    let(:index_options) do
      resource
      { owner: [owner.login.upcase, 'SOMETHING'].join(',') }
    end

    it "should respond with the correct number of items" do
      expect(json_response[api_resource_name].length).to eq(expected_count)
    end

    it "should respond with the correct item" do
      owner_id = json_response[api_resource_name][0]['links']['owner']['id']
      expect(owner_id).to eq(resource.owner.id.to_s)
    end
  end
end
