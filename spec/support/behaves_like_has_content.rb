shared_examples "has content" do
  context "missing content_association" do
    it "should not be valid" do
      expect(translatable_without_content).to be_invalid
    end

    it "should have the correct error message" do
      translatable_without_content.valid?
      error_key = "#{described_class.name.underscore}_contents".to_sym
      expect(translatable_without_content.errors[error_key]).to eq(["can't be blank"])
    end
  end

  describe "#primary_language" do
    let(:factory) { primary_language_factory }
    let(:locale_field) { :primary_language }

    it_behaves_like "a locale field"
  end

  describe "#available_languages" do
    it "should return a list of available languages" do
      expect(translatable.available_languages).to include('en-gb')
    end
  end
end
