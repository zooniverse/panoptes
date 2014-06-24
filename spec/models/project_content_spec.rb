require 'spec_helper'

RSpec.describe ProjectContent, :type => :model do
  let(:project_content) { build(:project_content) }
  it "should have a valid factory" do
    expect(project_content).to be_valid
  end
  
  describe "#language" do
    let(:factory) { :project_content }
    let(:locale_field) { :language }
    
    it_behaves_like "a locale field"
  end

  it "should require title to be present" do
    expect(build(:project_content, title: nil)).to_not be_valid
  end

  it "should require description to be present" do
    expect(build(:project_content, description: nil)).to_not be_valid
  end
end
