require 'spec_helper'

RSpec.describe MediumRemovalWorker do
  it 'should delete the given src path' do
    expect(MediaStorage).to receive(:delete_file)
    subject.perform('test/path.txt')
  end
end
