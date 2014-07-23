shared_examples "is translated content" do
  let(:content) { build(content_factory) }

  it "should have a valid factory" do
    expect(content).to be_valid
  end
  
  describe "#language" do
    let(:factory) { content_factory }
    let(:locale_field) { :language }
    
    it_behaves_like "a locale field"
  end
end
