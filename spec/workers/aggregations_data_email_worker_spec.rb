require "spec_helper"

RSpec.describe AggregationDataMailerWorker do
  let(:project) { create(:project) }
  let(:media) { create(:medium, linked: project, type: "aggregation_export") }
  let(:s3_url) { media.src }

  it 'should deliver the mail' do
    expect{ subject.perform(media.id) }.to change{ ActionMailer::Base.deliveries.count }.by(1)
  end

  context "when the media can't be found" do
    it 'should not deliver the mail' do
      expect{ subject.perform(nil) }.not_to change{ ActionMailer::Base.deliveries.count }
    end
  end

  context 'when there are no recipients' do
    it 'does not call the mailer' do
      media.metadata["recipients"] = []
      media.save!
      expect(AggregationDataMailer).to receive(:aggregation_data).never
      subject.perform(media.id)
    end
  end
end
