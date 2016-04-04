require 'spec_helper'

RSpec.describe WorkflowContent, :type => :model do
  let(:content_factory) { :workflow_content }
  let(:parent_factory) { :workflow }

  it_behaves_like "is translated content"

  describe "#strings" do

    it "should not be valid with a missing strings object" do
      expect(build(:workflow_content, strings: nil)).to be_invalid
    end

    it "should allow an empty hash of strings" do
      expect(build(:workflow_content, strings: {})).to be_valid
    end
  end

  describe "versioning", versioning: true do
    let(:new_strings) { { label: "some stuff" } }
    subject do
      create(:workflow_content)
    end

    it { is_expected.to be_versioned }

    it 'should track changes to strings' do
      subject.update!(strings: new_strings)
      expect(subject.previous_version.strings).to_not eq(new_strings)
    end

    it 'should not track changes to langauges' do
      new_lang = 'en'
      subject.update!(language: new_lang)
      expect(subject.previous_version).to be_nil
    end

    it 'caches the new version number', :aggregate_failures do
      previous_number = subject.current_version_number
      subject.update!(strings: new_strings)
      expect(subject.current_version_number).to eq(previous_number + 1)
      expect(subject.current_version_number).to eq(ModelVersion.version_number(subject))
    end
  end
end
