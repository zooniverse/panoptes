shared_examples "it has custom owner links" do
  it "should have the custom owner resource links" do
    get :index
    resource_links = json_response[api_resource_name].map do |resource|
      resource["links"]["owner"].keys
    end
    expect(resource_links.flatten.uniq).to eq %w(id type href)
  end

  it "should have the formatted the custom owner href link" do
    get :index
    resource_href_links = json_response[api_resource_name].map do |resource|
      resource["links"]["owner"]["href"]
    end
    match_hrefs = resource_href_links.all? { |href| href.match(/.+\/\d+/) }
    expect(match_hrefs).to be_truthy
  end

  it "should have the custom owner top level link" do
    get :index
    owner_prefix = "#{api_resource_name}.owner"
    owner_link = json_response["links"][owner_prefix]
    expected = { "href" => "/{#{owner_prefix}.href}",
                 "type" => "owners" }
    expect(owner_link).to eq(expected)
  end
end
