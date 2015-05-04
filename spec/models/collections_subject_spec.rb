require 'spec_helper'

RSpec.describe CollectionsSubject do
  it 'should not be valid when a subject in a collection already exists' do
    og_cs =  create(:collections_subject)
    test_cs = build(:collections_subject, subject: og_cs.subject, collection: og_cs.collection)
    expect(test_cs).to_not be_valid
  end
end
