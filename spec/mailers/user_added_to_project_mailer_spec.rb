require "spec_helper"

RSpec.describe UserAddedToProjectMailer, :type => :mailer do
  let(:project) { create(:project) }
  let(:user) { project.owner }
  let(:roles) { ["collaborator"] }
  let(:mail) { UserAddedToProjectMailer.added_to_project(user, project, roles)}

  describe "#added_to_project" do

    it "mails the correct user" do
      expect(mail.to).to include(user.email)
    end

    it 'comes from no-reply@zooniverse.org' do
      expect(mail.from).to include('no-reply@zooniverse.org')
    end

    it 'has the correct subject' do
      expect(mail.subject).to eq("You've been added to a new Zooniverse project!")
    end

    it 'has the project name in the body' do
      expect(mail.body.encoded).to match("#{project.display_name}")
    end

    it 'includes the lab URL if the user is a collaborator' do
      expect(mail.body.encoded).to match("https://zooniverse.org/lab/#{ project.id }")
    end

    it 'does not include the lab URL if the user is not a collaborator' do
      newmail = UserAddedToProjectMailer.added_to_project(user, project, ['expert'])
      expect(newmail.body.encoded).to_not match("https://zooniverse.org/lab/#{ project.id }")
    end
  end
end
