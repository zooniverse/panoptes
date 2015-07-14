require 'spec_helper'

describe Collection, :type => :model do
  let(:collection) { create(:collection) }
  let(:owned) { collection }
  let(:not_owned) { build(:collection, owner: nil, project: nil) }
  let(:activatable) { collection }
  let(:locked_factory) { :collection }
  let(:locked_update) { {display_name: "A differet name"} }

  it_behaves_like "optimistically locked"

  it_behaves_like "is ownable"
  it_behaves_like "activatable"

  it "should have a valid factory" do
    expect(build(:collection)).to be_valid
  end

  it "should not be valid without a display_name" do
    aggregate_failures "display_name validation" do
      collection = build(:collection, display_name: nil)
      expect(collection).to be_invalid
      collection.valid?
      expect(collection.errors[:display_name]).to include("can't be blank")
    end
  end

  it 'should require unique displays name for an owner' do
    owner = create(:user)
    expect(create(:collection, display_name: "hi fives", owner: owner)).to be_valid
    expect(build(:collection, display_name: "hi fives", owner: owner)).to_not be_valid
  end

  it 'should not require display name uniquenames between owners' do
    expect(create(:collection, display_name: "test collection", owner: create(:user))).to be_valid
    expect(create(:collection, display_name: "test collection", owner: create(:user))).to be_valid
  end

  it 'should be valid when a subject is added twice' do
    col = create(:collection_with_subjects)
    sub = col.subjects.first
    expect{ col.subjects << sub }.to raise_error(ActiveRecord::RecordInvalid)
  end

  describe "#subjects" do
    let(:collection) { create(:collection_with_subjects) }

    it "should have many subjects" do
      expect(collection.subjects).to all( be_a(Subject) )
    end
  end
end
