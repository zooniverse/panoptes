shared_examples "a filter has many serializer" do
  let(:scope) { resource.class.all }
  let(:serializer) { described_class }
  let(:relation_id) { resource.send(relation).first.id }
  let(:relation_key) { "#{relation.to_s.singularize}_id" }
  let(:params) { { page_size: 1, relation_key => relation_id }.symbolize_keys }
  let(:resource_key) { serializer.key }

  before do
    next_page_resource
  end

  it "handles paging query params for has_many_filtering" do
    result = serializer.page(params, scope, {})
    next_href = result.dig(:meta, resource_key, :next_href)
    expected_href = "/#{resource_key}?page=2&page_size=1&#{relation_key}=#{relation_id}"
    expect(next_href).to eq(expected_href)
  end
end
