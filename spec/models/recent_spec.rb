require 'spec_helper'

RSpec.describe Recent, :type => :model do
  it 'should not be valid without a classification' do
    expect(build(:recent, classification: nil)).to_not be_valid
  end

  it 'should not be valid without a subject' do
    expect(build(:recent, subject: nil)).to_not be_valid
  end

  describe "::create_from_classification" do
    it 'should create recent for each subject' do
      classification = create(:classification)
      subjects = classification.subject_ids
      Recent.create_from_classification(classification)
      expect(Recent.where(subject_id: subjects).count).to eq(subjects.length)
    end
  end
end
