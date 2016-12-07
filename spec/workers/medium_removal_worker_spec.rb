require 'spec_helper'

RSpec.describe MediumRemovalWorker do
  it 'should delete the given src path' do
    expect(MediaStorage).to receive(:delete_file)
    subject.perform('test/path.txt')
  end

  it 'should skip any access denied media paths' do
    allow(MediaStorage).to receive(:delete_file).and_raise(AWS::S3::Errors::AccessDenied)
    expect { subject.perform('test/path.txt') }.not_to raise_error
  end
end
