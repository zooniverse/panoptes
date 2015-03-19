require "spec_helper"

describe WorkflowReloadWorker do
  subject { described_class.new }

  it 'should call the CellectClient' do
    expect(CellectClient).to receive(:reload_workflow).with(1)
    subject.perform(1)
  end

end
