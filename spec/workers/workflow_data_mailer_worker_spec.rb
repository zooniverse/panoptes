require "spec_helper"

RSpec.describe WorkflowDataMailerWorker do
  let(:project) { create(:project) }
  let(:s3_url) { "https://fake.s3.url.example.com" }

  it 'should deliver the mail' do
    expect{ subject.perform(project.id, "project", s3_url, ["zach@zooniverse.org"]) }.to change{ ActionMailer::Base.deliveries.count }.by(1)
  end

  context 'when there are no recipients' do
    it 'does not call the mailer' do
      expect(WorkflowDataMailer).to receive(:subject_data).never
      subject.perform(project.id, "project", s3_url, [])
    end
  end
end
