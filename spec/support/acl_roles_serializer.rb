shared_examples "an ACL roles serializer" do
  it "should have the custom owner resource links" do
    get :index
    resource_links = json_response[api_resource_name].map do |resource|
      resource["links"]["owner"].keys
    end
    expect(resource_links.flatten.uniq).to eq %w(id type href)
  end

  it "should have the custom owner top level link" do
    get :index
    owner_prefix = "#{api_resource_name}.owner"
    owner_link = json_response["links"][owner_prefix]
    expected = {"type" => "owners", "href" => "/{#{owner_prefix}.href}/{#{owner_prefix}.id}"}
    expect(owner_link).to eq(expected)
  end
end
