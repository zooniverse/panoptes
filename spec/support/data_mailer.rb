RSpec.shared_examples "data mailer" do |data_type, method|
  let(:project) { create(:project) }
  let(:owner) { project.owner }
  let(:mail) do
    described_class.send(method, project, "https://fake.s3.url.example.com", emails)
  end
  let(:emails) { %w(test@examples.com admin@example.com) }

  it_behaves_like "email generic unsubscribe links"

  it 'should mail the project the included emails' do
    expect(mail.to).to include(*emails)
  end

  it 'should come from no-reply@zooniverse.org' do
    expect(mail.from).to include('no-reply@zooniverse.org')
  end

  it 'should have "Classification Data is Ready" as the subject' do
    expect(mail.subject).to eq("#{data_type} Data is Ready")
  end

  it 'should have the link in the body' do
    expect(mail.body.encoded).to match("https://fake.s3.url.example.com")
  end

  it 'should have the project display name in the body' do
    expect(mail.body.encoded).to match(project.display_name)
  end
end
