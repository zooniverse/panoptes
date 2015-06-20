require "spec_helper"

RSpec.describe SubjectDataMailerWorker do
  let(:project) { create(:project) }
  let(:s3_url) { "https://fake.s3.url.example.com" }

  it 'should deliver the mail' do
    expect{ subject.perform(project.id, s3_url, ["ed.paget@gmail.com"]) }.to change{ ActionMailer::Base.deliveries.count }.by(1)
  end
end
