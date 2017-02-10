require 'spec_helper'

RSpec.describe Recent, :type => :model do
  describe "association validations" do
    let(:classification) { create(:classification) }
    let(:recent) { build(:recent, classification: classification) }

    it 'should not be valid without a classification' do
      recent.classification = nil
      expect(recent).to_not be_valid
    end

    it 'should not be valid without a subject' do
      recent.subject = nil
      expect(recent).to_not be_valid
    end

    it 'should not be valid without a user_id' do
      allow(classification).to receive(:user_id).and_return(nil)
      recent.user_id = nil
      expect(recent).to_not be_valid
    end

    it 'should not be valid without a project_id' do
      allow(classification).to receive(:project_id).and_return(nil)
      recent.project_id = nil
      expect(recent).to_not be_valid
    end

    it 'should not be valid without a workflow_id' do
      allow(classification).to receive(:workflow_id).and_return(nil)
      recent.workflow_id = nil
      expect(recent).to_not be_valid
    end

    it 'should be valid without a user_group_id' do
      allow(classification).to receive(:user_group_id).and_return(nil)
      recent.user_group_id = nil
      expect(recent).to be_valid
    end
  end

  describe "::create_from_classification" do
    let(:classification) { create(:classification) }

    it 'should create recent for each subject' do
      subjects = classification.subject_ids
      expect {
        Recent.create_from_classification(classification)
      }.to change {
        Recent.where(subject_id: subjects).count
      }.by (subjects.length)
    end
  end
end
