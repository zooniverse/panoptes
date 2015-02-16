require 'spec_helper'

RSpec.describe RetirementSchemes::ClassificationCount do
  subject { described_class.new(10) }
  
  describe "#retire?" do
    context "retirement count is less than sms classification count" do
      it 'should be false' do
        sms = build(:set_member_subject, classification_count: 9)
        expect(subject.retire?(sms)).to be(false)
      end
    end
    
    context "retirement count is fewer than sms classification count" do
      it 'should be true' do
        sms = build(:set_member_subject, classification_count: 11)
        expect(subject.retire?(sms)).to be(true)
      end
    end
  end
end
