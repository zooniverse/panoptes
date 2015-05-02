require "spec_helper"

RSpec.describe ClassificationDataMailer, :type => :mailer do
  let(:project) { create(:project) }
  let(:owner) { project.owner }
  let(:mail) { ClassificationDataMailer.classification_data(project, "https://fake.s3.url.example.com")}

  let!(:collaborators) do
    users = create_list(:user, 2)
    users.map(&:identity_group).each do |u|
      create(:access_control_list, roles: ["collaborator"], resource: project, user_group: u)
    end
    users
  end

  it 'should mail the project owner' do
    expect(mail.to).to include(owner.email)
  end

  it 'should mail any project collaborators' do
    expect(mail.to).to include(*collaborators.map(&:email))
  end

  it 'should come from no-reply@zooniverse.org' do
    expect(mail.from).to include('no-reply@zooniverse.org')
  end

  it 'should have "Classification Data is Ready" as the subject' do
    expect(mail.subject).to eq("Classification Data is Ready")
  end

  it 'should have the link in the body' do
    expect(mail.body.encoded).to match("https://fake.s3.url.example.com")
  end

  it 'should have the project display name in the body' do
    expect(mail.body.encoded).to match(project.display_name)
  end
end
