RSpec.shared_examples "has item link" do
  it 'should have an item link' do
    expect(json_response[api_resource_name][0]["links"]).to include("item")
  end

  it 'should have full link data' do
    expect(json_response[api_resource_name][0]['links']['item']).to include("id" => resource.id.to_s,
                                                                            "href" => "/#{resource_class.model_name.route_key}/#{resource.id}",
                                                                            "type" => resource_class.model_name.plural)
  end
end


RSpec.shared_examples "a versioned resource" do
  let(:api_resource_name) { "versions" }
  let(:api_resource_attributes) { %w(id changeset whodunnit created_at) }
  let(:api_resource_links) { [ ] }

  before(:each) do
    PaperTrail.enabled = true
    PaperTrail.enabled_for_controller = true
    (num_times || 0).times do |n|
      update_proc.call(resource, n)
    end
    default_request user_id: authorized_user.id, scopes: scopes
  end

  after(:each) do
    PaperTrail.enabled = false
    PaperTrail.enabled_for_controller = false
  end

  describe "#user_for_paper_trail" do

    it 'should respond with the current user id when logged in' do
      expect(subject.send(:user_for_paper_trail)).to eq(authorized_user.id)
    end

    context "when not logged in" do
      it 'should respond with the current user id' do
        allow(subject).to receive(:current_resource_owner).and_return(nil)
        expect(subject.send(:user_for_paper_trail)).to eq("UnauthenticatedUser")
      end
    end
  end

  describe "#versions" do
    before(:each) do
      get :versions, { resource_param => resource.id }
    end

    it 'should include versions in the response' do
      expected_versions = num_times + (existing_versions || 0)
      expect(json_response["versions"].length).to eq(expected_versions)
    end

    it 'should respond ok' do
      expect(response.status).to eq(200)
    end

    it_behaves_like "has item link"
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

    it_behaves_like "has item link"
    it_behaves_like "an api response"
  end
end
