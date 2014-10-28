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
  
  describe "#is_primary?" do
    let(:parent) { build(parent_factory, primary_language: 'es-MX') }
    
    context "content model's language is same as project primary_language" do
      it 'should be truthy' do
        content = build(content_factory, language: 'es-MX', parent_factory => parent)
        expect(content.is_primary?).to be_truthy
      end
    end

    context "content model has non primary_language" do
      it 'should be falsy' do
        content = build(content_factory, language: 'en-US', parent_factory => parent)
        expect(content.is_primary?).to be_falsy
      end
    end
  end

  describe "#is_translator?" do
    let(:content) { create(content_factory) }
    let(:user) { create(:user) }
    
    context "when user is enrolled as a translator" do
      it 'should be truthy' do
        project = content.try(:project) || content.send(parent_factory).project
        create(:user_project_preference, project: project,  user: user, roles: ["translator"])
        expect(content.is_translator?(user)).to be_truthy
      end
    end

    context "when user is not enrolled" do
      it 'should be falsy' do
        expect(content.is_translator?(user)).to be_falsy
      end
    end
  end
end
