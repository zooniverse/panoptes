require 'spec_helper'

describe Translations::DiffEngine do
  let(:translation) { create :translation }
  let(:diff_engine) { described_class.new(translation) }

  it 'returns no changes if both are the same' do
    expect(diff_engine.outdated(translation)).to be_empty
  end

  it 'returns strings that are missing' do
    translation.update! strings: {hello: "Hello"}
    other = create :translation
    expect(diff_engine.outdated(other)).to match_array(["hello"])
  end

  it 'returns strings that are on an older translation' do
    translation.strings = {hello: "Hi there"}
    translation.string_versions = {hello: 2}
    other = create :translation, strings: {hello: "Hola"}, string_versions: {hello: 1}
    expect(diff_engine.outdated(other)).to match_array(["hello"])
  end
end
