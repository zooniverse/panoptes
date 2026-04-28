# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AggregationCompletedMailer, type: :mailer do
  let(:base_url) { 'https://example.com' }

  before do
    allow(ENV).to receive(:fetch).with('AGGREGATION_STORAGE_BASE_URL', '').and_return(base_url)
  end

  describe '#aggregation_complete' do
    let(:mail) { described_class.aggregation_complete(aggregation) }

    context 'with a successful aggregation' do
      let(:aggregation) { create(:aggregation, status: 'completed', uuid: 'asdf123asdf') }
      let(:uuid) { aggregation.uuid }
      let(:workflow) { aggregation.workflow }

      it 'mails the user' do
        expect(mail.to).to match_array([aggregation.user.email])
      end

      it 'includes the subject' do
        expect(mail.subject).to include('Your workflow aggregation was successful!')
      end

      it 'includes the zip file link' do
        expect(mail.body.encoded).to include("#{base_url}/#{uuid}/#{workflow.id}_aggregation.zip")
      end

      it 'includes the reductions file link' do
        expect(mail.body.encoded).to include("#{base_url}/#{uuid}/#{workflow.id}_reductions.csv")
      end

      it 'comes from no-reply@zooniverse.org' do
        expect(mail.from).to include('no-reply@zooniverse.org')
      end

      it 'has the success statement' do
        expect(mail.body.encoded).to include('The workflow was aggregated successfully.')
      end
    end

    context 'with a failed aggregation' do
      let(:aggregation) { create(:aggregation, status: 'failed') }

      it 'reports the failures statement' do
        expect(mail.body.encoded).to include('The workflow failed to aggregate.')
      end
    end
  end
end
