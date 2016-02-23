require 'spec_helper'

RSpec.describe Subjects::SeenRemover do
  let(:append_sms_ids) { (1..10).to_a }
  let(:workflow) { instance_double("Workflow")}
  let(:user) { instance_double("User") }
  let(:uss) { instance_double("UserSeenSubject") }
  let(:sms) { create(:set_member_subject) }
  let(:subject_ids) { [ sms.subject.id ] }
  let(:user_seens) { nil }

  subject { described_class.new(user_seens, append_sms_ids) }

  describe "#unseen_ids" do
    let(:result) { subject.unseen_ids }

    it "should return the whole set if there are no seen subjects" do
      expect(result).to match_array(append_sms_ids)
    end

    context "with seen subjects" do
      let(:user_seens) do
        build(:user_seen_subject,
          user: nil,
          workflow: nil,
          subject_ids: subject_ids
        )
      end
      it "should return the whole set if no seens match" do
        allow(user_seens).to receive(:subject_ids).and_return([])
        expect(result).to match_array(append_sms_ids)
      end

      it "should return the diff set when seens match inputs" do
        expected = append_sms_ids - subject_ids
        expect(result).to match_array(expected)
      end
    end
  end
end
