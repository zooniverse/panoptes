require "spec_helper"

RSpec.describe SubjectDataMailerWorker do
  let(:project) { create(:project) }
  let(:url) { "https://www.zooniverse.org/lab/123" }

  it 'should deliver the mail' do
    expect{ subject.perform(project.id, "project", url, ["zach@zooniverse.org"]) }.to change{ ActionMailer::Base.deliveries.count }.by(1)
  end

  context 'when there are no recipients' do
    it 'does not call the mailer' do
      expect(SubjectDataMailer).to receive(:subject_data).never
      subject.perform(project.id, "project", url, [])
    end
  end
end
