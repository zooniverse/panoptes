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

  describe "#is_translator" do
    let(:user) { create(:user) }
    
    context "when user has a translator role" do
      let!(:upp) do
        project = translatable.try(:project) || translatable
        create(:user_project_preference, user: user, project: project, roles: ["translator"])
      end
      
      it 'should return truthy' do
        expect(translatable.is_translator?(user)).to be_truthy
      end
    end

    context "when a user does not have a translator role" do
      it 'should return false if a user is not a translator' do
        expect(translatable.is_translator?(user)).to be_falsy
      end
    end
  end
  
  describe "::translatable_by" do
    let(:users) { create_list(:user, 2) }
    let(:private_model) do
      project = create(:project, visible_to: ["collaborator"])
      return project if :project == primary_language_factory 
      create(primary_language_factory, project: project)
    end
    let!(:upp) do
      project = translatable.try(:project) || translatable
      create(:user_project_preference, user: users.first, project: project, roles: ["translator"])
    end

    it 'should include projects a user is a translator for' do
      expect(described_class.translatable_by(users.first)).to match_array([translatable])
    end

    it 'should not include projects a user is not a translator for' do
      expect(described_class.translatable_by(users.first)).to_not include(private_model)
    end

    it 'should by empty when a user not a translator on any project' do
      expect(described_class.translatable_by(users[1])).to be_empty
    end
  end
end
