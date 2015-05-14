shared_examples "an indexable etag response" do

  it "should generate the etag from the response obj" do
    expected_etag = %("#{Digest::MD5.hexdigest(response.body)}")
    expect(response.headers["ETag"]).to eq(expected_etag)
  end
end
