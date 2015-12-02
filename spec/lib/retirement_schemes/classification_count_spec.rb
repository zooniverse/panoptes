require 'spec_helper'

RSpec.describe RetirementSchemes::ClassificationCount do
  subject { described_class.new(count: 10) }

  describe "#retire?" do
    context "retirement count is less than sms classification count" do
      it 'should be false' do
        count = build(:subject_workflow_count, classifications_count: 9)
        expect(subject.retire?(count)).to be(false)
      end
    end

    context "retirement count is fewer than sms classification count" do
      it 'should be true' do
        count = build(:subject_workflow_count, classifications_count: 11)
        expect(subject.retire?(count)).to be(true)
      end
    end
  end
end
