require 'spec_helper'

RSpec.describe RetirementSchemes::NeverRetire do
  subject { described_class.new }

  describe "#retire?"  do
    it 'should be false' do
      count = double("SubjectWorkflowCount")
      expect(subject.retire?(count)).to be(false)
    end
  end
end
