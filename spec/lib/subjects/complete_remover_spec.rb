require 'spec_helper'

RSpec.describe Subjects::CompleteRemover do
  let(:append_subject_ids) { (1..10).to_a | subject_ids }
  let(:workflow) { create(:workflow) }
  let(:user) { workflow.project.owner }
  let(:subject) { create(:subject) }
  let(:subject_ids) { [ subject.id ] }
  let(:complete_remover) do
    described_class.new(user, workflow, append_subject_ids)
  end

  describe "#incomplete_ids"  do
    let(:result) { complete_remover.incomplete_ids }

    it "should return the whole set if there are no seen or retired subjects" do
      expect(result).to match_array(append_subject_ids)
    end

    context "with an empty set" do
      let(:append_subject_ids){ [] }

      it "should fast return if the set is empty" do
        expect(subject).not_to receive(:retired_seen_ids)
        expect(result).to match_array([])
      end
    end

    context "with seen subjects" do

      it "should return the diff set when seens match inputs" do
        create(:user_seen_subject, user: user, workflow: workflow, subject_ids: subject_ids)
        expected = append_subject_ids - subject_ids
        expect(result).to match_array(expected)
      end
    end

    context "with retired subjects" do

      it "should return the diff set when retired match inputs" do
        create(:subject_workflow_status, subject: subject, workflow: workflow, retired_at: Time.now)
        expected = append_subject_ids - subject_ids
        expect(result).to match_array(expected)
      end
    end

    context "with retired and seen subjects" do
      let(:another_subject) { create(:subject) }

      it "should return the non retired seen set " do
        create(:subject_workflow_status, subject: another_subject, workflow: workflow, retired_at: Time.now)
        create(:user_seen_subject, user: user, workflow: workflow, subject_ids: subject_ids)
        expected = append_subject_ids - [ subject.id, another_subject.id ]
        expect(result).to match_array(expected)
      end
    end

  end
end
