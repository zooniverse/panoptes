require 'spec_helper'

describe Translations::DiffEngine do
  let(:diff_engine) { described_class.new(version) }
  let(:version) { create :translation_version }

  it 'returns no changes if both are the same' do
    expect(diff_engine.compare(version)).to be_empty
  end
end
