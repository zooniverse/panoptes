require 'spec_helper'

RSpec.describe Collection, :type => :model do
  let(:collection) { create(:collection) }
  let(:owned) { collection }
  let(:not_owned) { build(:collection, owner: nil) }
  let(:activatable) { collection }
  let(:visible) { collection }

  it_behaves_like "is ownable"
  it_behaves_like "activatable"
  it_behaves_like "has visibility controls"

  it "should have a valid factory" do
    expect(build(:collection)).to be_valid
  end

  describe "#subject" do
    let(:collection) { create(:collection_with_subjects) }

    it "should have many subjects" do
      expect(collection.subjects).to all( be_a(Subject) )
    end
  end
end
