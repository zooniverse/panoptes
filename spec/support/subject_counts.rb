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
end
