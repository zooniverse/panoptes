require 'spec_helper'

RSpec.describe WorkflowContent, :type => :model do
  let(:content_factory) { :workflow_content }
  let(:parent_factory) { :workflow }

  it_behaves_like "is translated content"

  describe "versioning" do
    subject do
      create(:workflow_content)
    end
    
    it { is_expected.to be_versioned }

    it 'should track changes to strings', versioning: true do
      new_strings = %w(some stuff)
      subject.update!(strings: new_strings)
      expect(subject.previous_version.strings).to_not eq(new_strings)
    end

    it 'should not track changes to langauges', versioning: true do
      new_lang = 'en'
      subject.update!(language: new_lang)
      expect(subject.previous_version).to be_nil
    end
  end
end
