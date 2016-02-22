require 'spec_helper'

RSpec.describe Subjects::SeenRemover do
  let(:append_sms_ids) { (1..10).to_a }
  let(:workflow) { instance_double("Workflow")}
  let(:user) { instance_double("User") }
  let(:uss) { instance_double("UserSeenSubject") }
  let(:sms) { create(:set_member_subject) }
  let(:subject_ids) { [ sms.subject.id ] }
  let(:seens) do
    build(:user_seen_subject,
      user: nil,
      workflow: nil,
      subject_ids: subject_ids
    )
  end
  subject { described_class.new(user, workflow, append_sms_ids) }

  describe "#unseen_ids" do
    it "should return the whole set if there are no seen subjects" do
      allow(subject)
        .to receive(:seen_before_sms_ids)
        .and_return([])
      expect(subject.unseen_ids).to match_array(append_sms_ids)
    end

    context "with seen subjects" do
      it "should return the whole set if no seens match" do
        allow(uss).to receive(:subject_ids).and_return([])
        allow(subject).to receive(:user_seen_subject).and_return(uss)
        expect(subject.unseen_ids).to match_array(append_sms_ids)
      end

      it "should return the diff set when seens match inputs" do
        allow(subject).to receive(:user_seen_subject).and_return(seens)
        expected = append_sms_ids - subject_ids
        expect(subject.unseen_ids).to match_array(expected)
      end
    end
  end
end
