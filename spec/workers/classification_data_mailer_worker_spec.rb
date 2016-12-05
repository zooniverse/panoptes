require 'spec_helper'

RSpec.describe ClassificationDataMailerWorker do
  let(:s3_url) { "https://fake.s3.url.example.com" }

  shared_examples 'is a mailer' do
    it 'should deliver the mail' do
      expect{ subject.perform(resource.id, resource.class.to_s.downcase, s3_url, ["zach@zooniverse.org"]) }.to change{ ActionMailer::Base.deliveries.count }.by(1)
    end

    context 'when there are no recipients' do
      it 'does not call the mailer' do
        expect(ClassificationDataMailer).to receive(:classification_data).never
        subject.perform(resource.id, resource.class.to_s.downcase, s3_url, [])
      end
    end
  end

  context 'when resource is a project' do
    let(:resource) { create(:project) }
    it_behaves_like 'is a mailer'
  end

  context 'when resource is a workflow' do
    let(:resource) { create(:workflow) }
    it_behaves_like 'is a mailer'
  end
end
