shared_examples "is creatable" do
  let(:created_id) { created_instance_id(api_resource_name) }

  context "a logged in user" do
    before(:each) do
      default_request scopes: scopes, user_id: authorized_user.id
      post :create, create_params
    end

    it "should return 201" do
      expect(response.status).to eq(201)
    end

    it 'should create the new resource' do
      created = resource_class.find(created_id)
      expect(created.send(test_attr)).to eq(test_attr_value)
    end

    it "should set the Location header as per JSON-API specs" do
      id = created_id
      location_header = response.headers["Location"]
      resource_url = "http://test.host/api/#{ api_resource_name }/#{ id }"
      expect(location_header).to eq(resource_url)
    end
    
    it_behaves_like 'an api response'
  end

  context "a non-logged in user" do
    before(:each) do
      default_request
      post :create, create_params
    end

    it "should return 401" do
      expect(response.status).to eq(401)
    end
  end
end
