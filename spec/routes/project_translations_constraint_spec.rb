require "spec_helper"

describe Routes::Constraints::ProjectTranslations do
  describe "#matches?", :focus do
    subject { Routes::Constraints::ProjectTranslations.new }

    it 'should match when translated_type is a project' do
      request = double(params: { translated_type: "project"})
      expect(subject.matches?(request)).to be true
    end

    it 'should not match when translated_type is not a project' do
      request = double(params: { translated_type: "organisation"})
      expect(subject.matches?(request)).to be false
    end

    it 'should not match when translated_type is missing' do
      request = double(params: {})
      expect(subject.matches?(request)).to be false
    end
  end
end
