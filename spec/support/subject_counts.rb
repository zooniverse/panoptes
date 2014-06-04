require 'spec_helper'

shared_examples "has subject_count" do
  describe "#subject_count" do
    it "return a count of the associated subjects" do
      expect(subject_relation.subject_count).to eq(subject_relation
                                                    .subject_sets
                                                      .map{ |set| set.subjects.count }
                                                      .reduce(&:+))
    end
  end
end
