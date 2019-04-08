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
