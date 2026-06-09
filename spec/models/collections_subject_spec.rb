require 'spec_helper'

RSpec.describe CollectionsSubject do
  it 'should not be valid when a subject in a collection already exists' do
    og_cs =  create(:collections_subject)
    test_cs = build(:collections_subject, subject: og_cs.subject, collection: og_cs.collection)
    expect(test_cs).to_not be_valid
  end

  describe 'subjects_count' do
    let(:collection) { create(:collection) }

    it 'increments subjects_count when a collections_subject is created' do
      expect(collection.subjects_count).to eq(0)
      create(:collections_subject, collection: collection)
      collection.reload
      expect(collection.subjects_count).to eq(1)
    end

    it 'decrements the subjects_count when a collections_subject is destroyed' do
      cs = create(:collections_subject, collection: collection)
      expect(collection.subjects_count).to eq(1)
      cs.destroy
      collection.reload
      expect(collection.subjects_count).to eq(0)
    end
  end
end
