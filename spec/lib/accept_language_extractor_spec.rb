require "spec_helper"

describe AcceptLanguageExtractor do
  describe "#parse_languages" do
    subject { AcceptLanguageExtractor.new("en-US,en;q=0.5,*") }

    it 'should ignore non-alpha languages' do
      expect(subject.parse_languages).to_not include("*")
    end

    it 'should include alpha languages' do
      expect(subject.parse_languages).to match_array(["en-us", "en"])
    end
  end
end
