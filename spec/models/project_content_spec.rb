require 'spec_helper'

RSpec.describe ProjectContent, :type => :model do
  let(:project_content) { build(:project_content) }
  it "should have a valid factory" do
    expect(project_content).to be_valid
  end

  it  "should require languages to be exactly 2 or 5 characters" do
    expect(build(:project_content, language: 'a')).to_not be_valid
    expect(build(:project_content, language: 'abasdf')).to_not be_valid
  end

  it "should require languages to conform to a format" do
    expect(build(:project_content, language: 'abasd')).to_not be_valid
    expect(build(:project_content, language: 'ab')).to be_valid
    expect(build(:project_content, language: 'ab-sd')).to be_valid
  end

  it "should require task_strings to be present" do
    expect(build(:project_content, task_strings: nil)).to_not be_valid
  end

  it "should require title to be present" do
    expect(build(:project_content, title: nil)).to_not be_valid
  end

  it "should require description to be present" do
    expect(build(:project_content, description: nil)).to_not be_valid
  end

end
