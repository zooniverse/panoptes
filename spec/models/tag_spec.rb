require 'spec_helper'

RSpec.describe Tag, type: :model do
  it 'should have a valid factory' do
    expect(build(:tag)).to be_valid
  end

  it 'should not be valid without a name' do
    expect(build(:tag, name: nil)).to_not be_valid
  end

  describe "::search_tags" do
    before(:each) do
      2.times do |n|
        create(:tag, name: "tag-#{n}")
      end

      create(:tag, name: "CARAWAY SEEDS")
    end

    it 'should fuzzy match tags' do
      expect(described_class.search_tags("tag").count).to eq(2)
    end

    it 'should allow you to search the associated models' do
      expect(Project.joins(:tags).merge(described_class.search_tags("tag")).count).to eq(2)
    end
  end

  describe "#downcase_name" do
    it 'should downcase the name before saving' do
      tag = build(:tag, name: "ASDF")
      tag.save!
      expect(tag.name).to eq('asdf')
    end
  end
end
