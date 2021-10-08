# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubjectSetCompletedMailerWorker do
  let(:subject_set) { create(:subject_set, num_workflows: 0) }

  it 'delivers the mail' do
    expect { described_class.new.perform(subject_set.id) }.to change{ ActionMailer::Base.deliveries.count }.by(1)
  end

  context 'with an unknown subject_set_id' do
    it 'raises an error so we know about it' do
      expect { described_class.new.perform(nil) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

end
