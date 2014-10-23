require 'spec_helper'

RSpec.describe ProjectContent, :type => :model do
  let(:content_factory) { :project_content }

  it_behaves_like "is translated content"

  it 'should require a title to be valid' do
    expect(build(:project_content, :title => nil )).to_not be_valid
  end

  it 'should require a description to be valid' do
    expect(build(:project_content, :description => nil )).to_not be_valid
  end

  describe "#is_primary?" do
    let(:project) { build(:project, primary_language: 'es-MX') }
    
    context "content model's language is same as project primary_language" do
      it 'should be truthy' do
        content = build(:project_content, language: 'es-MX', project: project)
        expect(content.is_primary?).to be_truthy
      end
    end

    context "content model has non primary_language" do
      it 'should be falsy' do
        content = build(:project_content, language: 'en-US', project: project)
        expect(content.is_primary?).to be_falsy
      end
    end
  end

  describe "#is_project_translator?" do
    let(:content) { create(:project_content) }
    let(:user) { create(:user) }
    
    context "when user is enrolled as a translator" do
      it 'should be truthy' do
        create(:user_project_preference, project: content.project,  user: user, roles: ["translator"])
        expect(content.is_project_translator?(user)).to be_truthy
      end
    end

    context "when user is not enrolled" do
      it 'should be falsy' do
        expect(content.is_project_translator?(user)).to be_falsy
      end
    end
  end
end
