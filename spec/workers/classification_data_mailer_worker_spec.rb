require 'spec_helper'

RSpec.describe ClassificationDataMailerWorker do
  let(:url) { "https://www.zooniverse.org/lab/123" }

  shared_examples 'is a classification data mailer' do
    it 'should deliver the mail' do
      expect{ subject.perform(resource.id, resource.class.to_s.downcase, url, ["zach@zooniverse.org"]) }.to change{ ActionMailer::Base.deliveries.count }.by(1)
    end

    context 'when there are no recipients'  do
      it 'does not call the mailer' do
        expect(ClassificationDataMailer).to receive(:classification_data).never
        subject.perform(resource.id, resource.class.to_s.downcase, url, [])
      end
    end
  end

  context 'when resource is a project' do
    let(:resource) { create(:project) }
    it_behaves_like 'is a classification data mailer'
  end

  context 'when resource is a workflow' do
    let(:resource) { create(:workflow) }
    it_behaves_like 'is a classification data mailer'
  end
end
