require 'spec_helper'

RSpec.describe ClassificationDataMailerWorker do
  let(:project) { create(:project) }
  let(:s3_url) { "https://fake.s3.url.example.com" }

  it 'should deliver the mail' do
    expect{ subject.perform(project.id, s3_url, ["ed.paget@gmail.com"]) }.to change{ ActionMailer::Base.deliveries.count }.by(1)
  end

  context 'when there are no recipients' do
    it 'does not call the mailer' do
      expect(ClassificationDataMailer).to receive(:classification_data).never
      subject.perform(project.id, s3_url, [])
    end
  end
end
