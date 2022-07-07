require 'spec_helper'

RSpec.describe SubjectRemovalWorker do
  let(:subject_id) { 1 }
  let(:feature_name) { "remove_orphan_subjects" }
  let(:remover) { instance_double(Subjects::Remover) }

  it 'should call the orphan remover cleanup when enabled' do
    Flipper.enable(feature_name)
    expect(Subjects::Remover).to receive(:new).with(subject_id).and_return(remover)
    expect(remover).to receive(:cleanup)
    subject.perform(subject_id)
  end

  it 'should not call the orphan remover cleanup when disabled' do
    expect(Subjects::Remover).not_to receive(:new)
    expect(remover).not_to receive(:cleanup)
    subject.perform(subject_id)
  end
end
