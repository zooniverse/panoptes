require 'spec_helper'

RSpec.describe InatImportCompletedMailerWorker do
  let(:ss_import) { create(:subject_set_import) }

  it 'should deliver the mail' do
    expect{ subject.perform(ss_import) }.to change{ ActionMailer::Base.deliveries.count }.by(1)
  end

  context "missing attributes" do
    it "is missing a ss_import and doesn't send" do
      expect{ subject.perform(nil) }.to not_change{ ActionMailer::Base.deliveries.count }
        .and raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'with an unknown subject_set_id' do
    it 'raises an error so we know about it' do
      expect { subject.perform(nil) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
