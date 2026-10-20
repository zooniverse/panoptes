# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserAddedToCollectionMailerWorker do
  describe '#perform' do
    subject(:mailer_worker) { described_class.new }

    let(:user) { create(:user) }
    let(:collection) { create(:collection) }
    let(:roles) { ['collaborator'] }

    it 'delivers email when user is added to a collection' do
      expect { mailer_worker.perform(user.id, collection.id, roles) }.to change { 'ActionMailer::Base'.constantize.deliveries.count }.by(1)
    end

    context 'with missing attributes' do
      it 'does not send email if user is missing' do
        expect { mailer_worker.perform(nil, collection.id, roles) }.not_to change { 'ActionMailer::Base'.constantize.deliveries.count }
      end

      it 'does not send email if collection is missing' do
        expect { mailer_worker.perform(user.id, nil, roles) }.not_to change { 'ActionMailer::Base'.constantize.deliveries.count }
      end

      it 'does not send email if roles are missing' do
        expect { mailer_worker.perform(user.id, collection.id, nil) }.not_to change { 'ActionMailer::Base'.constantize.deliveries.count }
      end

      it 'does not send email if user has been scrubbed of email address' do
        UserInfoScrubber.scrub_personal_info!(user)
        expect { mailer_worker.perform(user.id, collection.id, roles) }.not_to change { 'ActionMailer::Base'.constantize.deliveries.count }
      end
    end

    context 'with invalid email' do
      [Net::SMTPSyntaxError, Net::SMTPFatalError].each do |error_klass|
        before do
          allow_any_instance_of(ActionMailer::MessageDelivery)
            .to receive(:deliver)
            .and_raise(error_klass.new('test@example.com,ox'))
          allow(user).to receive(:email).and_return('test@example.com,ox')
        end

        it 'attempts to send an email' do
          expect_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver)
          mailer_worker.perform(user.id, collection.id, roles)
        end

        it 'marks the user with invalid_email' do
          mailer_worker.perform(user.id, collection.id, roles)
          expect(user.reload.valid_email).to eq(false)
        end
      end
    end
  end
end
