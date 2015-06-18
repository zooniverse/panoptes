shared_examples "an api response" do
  it "should return the correct content type" do
    expect(response.content_type).to eq("application/vnd.api+json; version=1")
  end

  it "should include allowed attributes" do
    attrs = (api_resource_attributes + %w(id href)).uniq
    expect(json_response[api_resource_name]).to all( include(*attrs) )
  end

  it "should have links to other resources" do
    unless api_resource_links.empty?
      expect(json_response["links"]).to include(*api_resource_links)
    end
  end

  it "should have list the response instances" do
    expect(json_response[api_resource_name]).to be_an(Array)
  end
end
