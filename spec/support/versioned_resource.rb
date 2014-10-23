shared_examples "a versioned resource" do
  let(:api_resource_name) { "versions" }
  let(:api_resource_attributes) { %w(id changeset whodunnit created_at) }
  let(:api_resource_links) { [ ] }
  
  before(:each) do
    PaperTrail.enabled = true
    PaperTrail.enabled_for_controller = true
    update_block
    default_request user_id: user.id, scopes: scopes
  end

  after(:each) do
    PaperTrail.enabled = true
    PaperTrail.enabled_for_controller = true
  end
  
  describe "#versions" do
    before(:each) do
      get :versions, { resource_param => resource.id }
    end
    
    it 'should include versions in the response' do
      expect(json_response["versions"].length).to eq(11)
    end

    it 'should respond ok' do
      expect(response.status).to eq(200)
    end

    it_behaves_like "an api response"
  end

  describe "#version" do
    before(:each) do
      get :version, {resource_param => resource.id,
                     id: resource.versions.last.id}
    end
    
    it 'should include a version in the response' do
      expect(json_response["versions"].length).to eq(1)
    end

    it 'should respond ok' do
      expect(response.status).to eq(200)
    end

    it_behaves_like "an api response"
  end
end
