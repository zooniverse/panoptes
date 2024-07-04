# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AggregationCompletedMailerWorker do
  let(:aggregation) { create(:aggregation) }

  it 'delivers the mail' do
    expect { described_class.new.perform(aggregation.id) }.to change { ActionMailer::Base.deliveries.count }.by(1)
  end

  context 'with missing attributes' do
    it 'is missing an aggregation and does not send' do
      expect { described_class.new.perform(nil) }.to not_change { ActionMailer::Base.deliveries.count }
        .and raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
