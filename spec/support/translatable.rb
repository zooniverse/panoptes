shared_examples "is translatable" do

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

  describe "#primary_content" do
    it "should have a primary_content association" do
      expected_content_class = translatable.class.content_model
      expect(translatable.primary_content).to be_a(expected_content_class)
    end

    context "without a primary_content association" do
      before do
        translatable.send(:"#{described_class.name.underscore}_contents=", [])
        translatable.primary_content = nil
        translatable.valid?
      end

      it "should not be valid" do
        expect(translatable).to be_invalid
      end

      it "should have the correct error message" do
        expect(translatable.errors[:primary_content]).to eq(["can't be blank"])
      end
    end
  end

  describe "#primary_language" do
    let(:factory) { primary_language_factory }
    let(:locale_field) { :primary_language }

    it_behaves_like "a locale field"
  end

  describe "#available_languages" do
    it "should return a list of available languages" do
      expect(translatable.available_languages).to include('en')
    end
  end

  describe "::scope_for" do
    let(:users) { create_list(:user, 2) }
    let!(:acl) do
      resource = translatable.try(:project) || translatable
      create(:access_control_list,
             user_group: users.first.identity_group,
             resource: resource,
             roles: ["translator"])
    end

    it 'should include projects a user is a translator for' do
      expect(described_class.scope_for(:translate, ApiUser.new(users.first))).to match_array([translatable])
    end

    it 'should not include projects a user is not a translator for' do
      expect(described_class.scope_for(:translate, ApiUser.new(users.first))).to_not include(private_model)
    end

    it 'should by empty when a user not a translator on any project' do
      expect(described_class.scope_for(:translate, ApiUser.new(users[1]))).to be_empty
    end
  end
end
