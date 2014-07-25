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
end
