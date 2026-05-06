require 'spec_helper'

RSpec.describe RecentsCleanupWorker, type: :worker do
  describe '#perform' do
    let(:worker) { described_class.new }

    context 'Temporal Sweep' do
      let(:user) { create(:user)}

      it 'deletes recents older than 14 days' do
        old_cls = create(:classification, user: user, created_at: 15.days.ago)
        old_recent = create(:recent, classification: old_cls)

        # Make sure the recent's created_at isn't overridden by the factory
        old_recent.update_column(:created_at, old_cls.created_at)

        new_cls = create(:classification, user: user, created_at: 1.days.ago)
        new_recent = create(:recent, classification: new_cls)
        new_recent.update_column(:created_at, new_cls.created_at)


        expect {
          worker.perform
        }.to change { Recent.exists?(old_recent.id) }.from(true).to(false)

        expect(Recent.exists?(new_recent.id)).to be true
      end
    end

    context 'Volume sweep' do
      let(:user) { create(:user)}

      it 'keeps the 20 newest recents and deletes the rest for a recently active user' do
        old_recents = []
        5.times {
          old_cls = create(:classification, user: user, created_at: 15.days.ago)
          old_recent = create(:recent, classification: old_cls)
          old_recent.update_column(:created_at, old_cls.created_at)
          old_recents << old_recent
        }

        new_recents = []
        20.times {
          new_cls = create(:classification, user: user, created_at: 30.minutes.ago)
          new_recent = create(:recent, classification: new_cls)
          new_recent.update_column(:created_at, new_cls.created_at)
          new_recents << new_recent
        }

        expect(Recent.where(user_id: user.id).count).to eq(25)
        expect {
          worker.perform
        }.to change { Recent.count }.by(-5)

        # Confirm it was the 5 older ones that were deleted
        old_records = Recent.where('created_at < ?', 10.days.ago)
        expect(old_records).to be_empty
      end

      it 'does not delete anything if a recently active user has 20 or fewer recents' do
        15.times {
          cls = create(:classification, user: user, created_at: 30.minutes.ago)
          rec = create(:recent, classification: cls)
          rec.update_column(:created_at, cls.created_at)
        }

        expect {
          worker.perform
        }.not_to change { Recent.count }
      end

      it 'ignores users who have not been active in the last hour' do
        # The user hasn't been active in the past hour, so these recents are ignored
        # They'll be cleaned up by the temporal sweep when they're older than 14 days

        25.times {
          cls = create(:classification, user: user, created_at: 2.hours.ago)
          rec = create(:recent, classification: cls)
          rec.update_column(:created_at, cls.created_at)
        }

        expect {
          worker.perform
        }.not_to change { Recent.count }
      end
    end
  end
end