shared_examples "is translatable" do
  describe "#primary_language" do
    let(:factory) { primary_language_factory }
    let(:locale_field) { :primary_language }
    
    it_behaves_like "a locale field"
  end

  describe "#content_for" do
    it "should return the contents for the given language" do
      expect(translatable.content_for(['en'], ["id"])).to be_a(translatable.class.content_model)
    end

    it "should return the given fields for the given langauge" do
      expect(translatable.content_for(['en'], ["id"]).try(:id)).to_not be_nil
      expect(translatable.content_for(['en'], ["id"]).try(:title)).to be_nil
    end

    it "should match less specific locales" do
      expect(translatable.content_for(['en-US'], ["id"])).to be_a(translatable.class.content_model)
    end
  end

  describe "#available_languages" do
    it "should return a list of available languages" do
      expect(translatable.available_languages).to include('en')
    end
  end
end
