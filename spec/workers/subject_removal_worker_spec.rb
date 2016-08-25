require 'spec_helper'

RSpec.describe SubjectRemovalWorker do
  let(:subject_id) { 1 }

  # TODO: reinstate this when the cleanup code is not killing the db
  # it 'should call the orphan remover cleanup' do
  #   remover = instance_double(Subjects::Remover)
  #   expect(Subjects::Remover).to receive(:new).with(subject_id).and_return(remover)
  #   expect(remover).to receive(:cleanup)
  #   subject.perform(subject_id)
  # end

  # remove this when the above is fixed
  it 'should not call the orphan remover cleanup', :focus do
    expect(Subjects::Remover).not_to receive(:new)
    subject.perform(subject_id)
  end
end
