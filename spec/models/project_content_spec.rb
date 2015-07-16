require 'spec_helper'

RSpec.describe ProjectContent, :type => :model do
  let(:content_factory) { :project_content }
  let(:parent_factory) { :project }

  it_behaves_like "is translated content"

  it 'should require a title to be valid' do
    expect(build(:project_content, :title => nil )).to_not be_valid
  end

  it 'should require a description to be valid' do
    expect(build(:project_content, :description => nil )).to_not be_valid
  end

  it 'should restrict the maximum length of desciption' do
    expect(build(:project_content, description: '0' * 301)).to_not be_valid
  end

  it 'should restrict the maximum length of workflow_desciption' do
    expect(build(:project_content, workflow_description: '0' * 501)).to_not be_valid
  end

  it 'should restrict the maximum length of title' do
    expect(build(:project_content, title: '0' * 256)).to_not be_valid
  end

  it 'should restrict the maximum length of introduction' do
    expect(build(:project_content, introduction: '0' * 1501)).to_not be_valid
  end

  describe "versioning" do
    subject do
      create(:project_content)
    end

    it { is_expected.to be_versioned }

    it 'should track changes to description', versioning: true do
      new_desc = "a boring old project"
      subject.update!(description: new_desc)
      expect(subject.previous_version.description).to_not eq(new_desc)
    end

    it 'should not track changes to language', versioning: true do
      new_lang = 'en'
      subject.update!(language: new_lang)
      expect(subject.previous_version).to be_nil
    end
  end
end
