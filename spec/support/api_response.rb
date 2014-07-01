shared_examples "an api response" do
  it "should return the correct content type" do
    expect(response.content_type).to eq("application/json")
  end

  it "should include allowed attributes" do
    expect(json_response[api_resource_name]).to all( include(*api_resource_attributes) )
  end

  it "should have links to other resources" do
    expect(json_response["links"]).to include(*api_resource_links)
  end

  it "should have list the response instances" do
    expect(json_response[api_resource_name]).to be_an(Array)
  end
end
