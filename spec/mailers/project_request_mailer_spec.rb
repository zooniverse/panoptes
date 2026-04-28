require "spec_helper"

RSpec.describe ProjectRequestMailer, type: :mailer do
  let(:configured_bcc) { "project-bcc@example.org" }
  let(:project) { create(:project) }
  let(:mail) do
    described_class.project_request("beta", project.id)
  end
  let(:emails) do
    [project.owner.email].concat(Panoptes.project_request.recipients)
  end

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('PROJECT_REQUEST_BCC', '').and_return(configured_bcc)
    Panoptes.instance_variable_set(:@project_request, nil)
  end

  after do
    Panoptes.instance_variable_set(:@project_request, nil)
  end

  it 'should send emails to the project owner and the designated recipients' do
    expect(mail.to).to include(*emails)
  end

  it 'should send a bcc emails to the designated recipients' do
    expect(mail.bcc).to include(*Panoptes.project_request.bcc)
  end

  it 'should come from no-reply@zooniverse.org' do
    expect(mail.from).to include('no-reply@zooniverse.org')
  end

  it 'should indicate the request type in the subject' do
    expect(mail.subject).to match(/beta/)
  end

  it 'should have a link to the project in the body' do
    expected_regex = %r{#{Panoptes.project_request.base_url}/projects/#{project.slug}}
    expect(mail.body.encoded).to match(expected_regex)
  end
end
