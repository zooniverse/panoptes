require 'spec_helper'

shared_examples "has subject_count" do
  describe "#subjects_count" do
    it "return a count of the associated subjects" do
      expect(subject_relation.subjects_count).to eq(subject_relation
                                                     .subject_sets
                                                     .map{ |set| set.subjects.count }
                                                     .reduce(&:+))
    end
  end

  describe "#retired_subjects_count" do
    it "return a count of the associated retired subjects" do
      expect(subject_relation.retired_subjects_count).to eq(subject_relation
                                                             .subject_sets
                                                             .map{ |set| set.set_member_subjects.retired.count }
                                                             .reduce(&:+))
    end
  end

  describe "#finished?" do
    it 'should be true when the subject count and retired count are equal' do
      subject_relation.subject_sets.each do |set|
        set.update!(retired_set_member_subjects_count: set.set_member_subjects_count)
      end
                                             
      expect(subject_relation).to be_finished
    end
  end
end
