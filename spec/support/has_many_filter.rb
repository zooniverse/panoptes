RSpec.shared_examples "has many filterable" do |relation|
  it "should be filtered by workflow_id" do
    resource = resources.first
    param = "#{relation.to_s.singularize}_id"
    get :index, param => resource.send(relation).first.id.to_s
    expect(json_response[api_resource_name][0]["id"]).to eq(resource.id.to_s)
  end
end
