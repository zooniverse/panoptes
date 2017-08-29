require "spec_helper"

describe Routes::Constraints::Translations do
  describe "#matches?", :focus do
    subject { Routes::Constraints::Translations.new }

    %w(project organization workflow tutorial field_guide page).each do |translated_type|
      it 'should match when translated_type is a #{translated_type}' do
        request = double(params: { translated_type: translated_type })
        expect(subject.matches?(request)).to be true
      end

      it 'should not match when translated_type is missing' do
        request = double(params: {})
        expect(subject.matches?(request)).to be false
      end

      context "with id param" do
        it 'should match when id is set and translated_type is a project' do
          request = double(params: { id: 1, translated_type: translated_type})
          expect(subject.matches?(request)).to be true
        end

        it 'should not match when id is invalid and translated_type is a project' do
          request = double(params: { id: "nan", translated_type: translated_type})
          expect(subject.matches?(request)).to be true
        end
      end
    end
  end
end
