# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubjectSetCompletedMailerWorker, :focus do
  let(:subject_set) { create(:subject_set, num_workflows: 0) }
  let(:project) { subject_set.project }
  let(:user) { create(:user) }

  it 'delivers the mail' do
    expect { described_class.new.perform(project.id) }.to change{ ActionMailer::Base.deliveries.count }.by(1)
  end

  context 'with an unknown project' do
    it 'does not deliver any mail' do
      expect { described_class.new.perform(nil) }.not_to change{ ActionMailer::Base.deliveries.count }
    end
  end

end
