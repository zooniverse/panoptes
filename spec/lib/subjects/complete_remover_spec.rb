require 'spec_helper'

RSpec.describe Subjects::CompleteRemover do
  let(:append_sms_ids) { (1..10).to_a | sms_ids }
  let(:workflow) { create(:workflow) }
  let(:user) { workflow.project.owner }
  let(:sms) { create(:set_member_subject) }
  let(:sms_ids) { [ sms.id ] }
  let(:subject_ids) { [ sms.subject.id ] }

  subject { described_class.new(user, workflow, append_sms_ids) }

  describe "#incomplete_ids" do
    let(:result) { subject.incomplete_ids }

    it "should return the whole set if there are no seen or retired subjects" do
      expect(result).to match_array(append_sms_ids)
    end

    context "with an empty set" do
      let(:append_sms_ids){ [] }

      it "should fast return if the set is empty" do
        expect(subject).not_to receive(:retired_seen_ids)
        expect(result).to match_array([])
      end
    end

    context "with seen subjects" do

      it "should return the diff set when seens match inputs" do
        create(:user_seen_subject, user: user, workflow: workflow, subject_ids: subject_ids)
        expected = append_sms_ids - sms_ids
        expect(result).to match_array(expected)
      end
    end

    context "with retired subjects" do

      it "should return the diff set when retired match inputs" do
        create(:subject_workflow_status, subject: sms.subject, workflow: workflow, retired_at: DateTime.now)
        expected = append_sms_ids - sms_ids
        expect(result).to match_array(expected)
      end
    end

    context "with retired and seen subjects" do
      let(:another_sms) { create(:set_member_subject) }
      let(:sms_ids) { [ sms.id, another_sms.id ] }

      it "should return the non retired seen set " do
        create(:subject_workflow_status, subject: another_sms.subject, workflow: workflow, retired_at: DateTime.now)
        create(:user_seen_subject, user: user, workflow: workflow, subject_ids: subject_ids)
        expected = append_sms_ids - sms_ids
        expect(result).to match_array(expected)
      end
    end

  end
end
