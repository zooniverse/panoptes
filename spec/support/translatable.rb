shared_examples "is translatable" do

  context "missing content_association" do

    it "should not be valid" do
      expect(translatable_without_content).to be_invalid
    end

    it "should have the correct error message" do
      translatable_without_content.valid?
      error_key = "#{locked_factory}_contents".to_sym
      expect(translatable_without_content.errors[error_key]).to eq(["can't be blank"])
    end
  end

  describe "::load_with_langauges" do
    subject do
      translatable
      results = described_class.load_with_languages(described_class.all, ['en-US'])
      results
    end

    it { is_expected.to_not be_empty }

    it 'should include content with the requested languages' do
      subject.each do |translatable|
        expect(translatable.content_association.map(&:language)).to include('en-US')
      end
    end

    it 'should fuzzy match the locale' do
      subject.each do |translatable|
        expect(translatable.content_association.map(&:language)).to include('en')
      end
    end

    it 'should not load other langauges' do
      subject.each do |translatable|
        expect(translatable.content_association.map(&:language)).to_not include('zh-TW')
      end
    end

    it 'should always load the primary_content' do
      results = described_class.load_with_languages(described_class.all, ['zh-TW'])
      results.each do |translatable|
        expect(results.content_association.map(&:language)).to include('en')
      end
    end
  end

  describe "#primary_language" do
    let(:factory) { primary_language_factory }
    let(:locale_field) { :primary_language }

    it_behaves_like "a locale field"
  end

  describe "#content_for" do
    it "should return the contents for the given language" do
      expect(translatable.content_for(['en'])).to be_a(translatable.class.content_model)
    end

    it "should match less specific locales" do
      expect(translatable.content_for(['en-US'])).to be_a(translatable.class.content_model)
    end

    it 'should load the primary content if nothing is found' do
      expect(translatable.content_for(['es-MX'])).to eq(translatable.primary_content)
    end

    context "after ::load_with_languages" do
      it 'should not make another sql query' do
        translatable
        result = described_class.load_with_languages(described_class.all, ['en-US'])
        result.each do |translatable|
          expect(translatable.content_for(['zh'])).to eq(translatable.primary_content)
        end
      end
    end
  end

  describe "#available_languages" do
    it "should return a list of available languages" do
      expect(translatable.available_languages).to include('en')
    end
  end

  describe "::scope_for" do
    let(:users) { create_list(:user, 2) }
    let!(:private_model) do
      project = create(:project, private: true)
      return project if :project == primary_language_factory
      create(primary_language_factory, project: project)
    end

    let!(:acl) do
      project = translatable.try(:project) || translatable
      create(:access_control_list,
             user_group: users.first.identity_group,
             resource: project,
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
