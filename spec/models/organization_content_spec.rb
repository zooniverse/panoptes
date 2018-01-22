require 'spec_helper'

RSpec.describe OrganizationContent, :type => :model do
  it_behaves_like "is translated content" do
    let(:content_factory) { :organization_content }
    let(:parent_factory) { :organization }
  end

  it 'should require a title to be valid' do
    expect(build(:organization_content, :title => nil )).to_not be_valid
  end

  it 'should require a description to be valid' do
    expect(build(:organization_content, :description => nil )).to_not be_valid
  end

  it 'should restrict the maximum length of desciption' do
    expect(build(:organization_content, description: '0' * 301)).to_not be_valid
  end

  it 'should restrict the maximum length of title' do
    expect(build(:organization_content, title: '0' * 256)).to_not be_valid
  end

  it 'should restrict the maximum length of introduction' do
    expect(build(:organization_content, introduction: '0' * 5001)).to_not be_valid
  end

  it 'should restrict the maximum length of announcement' do
    expect(build(:organization_content, announcement: '0' * 5001)).to_not be_valid
  end

  describe "versioning" do
    subject do
      create(:organization_content)
    end

    it { is_expected.to be_versioned }

    it 'should track changes to description', versioning: true do
      new_desc = "an exciting new organization"
      subject.update!(description: new_desc)
      expect(subject.previous_version.description).to_not eq(new_desc)
    end

    it 'should not track changes to language', versioning: true do
      expect {
        subject.update!(language: 'es-mx')
      }.not_to change { subject.previous_version }
    end
  end
end
