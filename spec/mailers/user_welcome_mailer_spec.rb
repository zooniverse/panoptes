require "spec_helper"

RSpec.describe UserWelcomeMailer, :type => :mailer do
  let(:project) { create(:project) }
  let(:user) { project.owner }
  let(:mail) { UserWelcomeMailer.welcome_user(user)}

  describe "#welcome_email" do

    it 'should mail the user' do
      expect(mail.to).to include(user.email)
    end

    it 'should come from no-reply@zooniverse.org' do
      expect(mail.from).to include('no-reply@zooniverse.org')
    end

    it 'should have the correct subject' do
      expect(mail.subject).to eq("Welcome to the Zooniverse!")
    end

    it 'should have the user name in the body' do
      expect(mail.body.encoded).to match("#{user.display_name}")
    end

    it 'should have the correct body content' do
      pending
    end
  end

  describe "#project_welcome_email" do
    let(:mail) { UserWelcomeMailer.project_welcome_user(user, project) }

    it 'should mail the user' do
      expect(mail.to).to include(user.email)
    end

    it 'should come from no-reply@zooniverse.org' do
      expect(mail.from).to include('no-reply@zooniverse.org')
    end

    it 'should have the correct subject' do
      expect(mail.subject).to eq("Welcome to the Zooniverse!")
    end

    it 'should have the user name in the body' do
      expect(mail.body.encoded).to match("#{user.display_name}")
    end

    it 'should have the project name in the body' do
      expect(mail.body.encoded).to match("#{project.display_name}")
    end

    it 'should have the correct body content' do
      pending
    end
  end
end
