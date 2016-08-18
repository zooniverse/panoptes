require 'spec_helper'

RSpec.describe SubjectRemovalWorker do
  let(:subject_id) { 1 }

  it 'should call the orphan remover cleanup' do
    remover = instance_double(Subjects::Remover)
    expect(Subjects::Remover).to receive(:new).with(subject_id).and_return(remover)
    expect(remover).to receive(:cleanup)
    subject.perform(subject_id)
  end
end
