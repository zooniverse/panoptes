require "spec_helper"

RSpec.describe DormantUserMailer, :type => :mailer do
  let(:user) { create(:user) }
  let(:mail) { DormantUserMailer.email_dormant_user(user)}

  describe "dormant_user_email" do

    it 'should mail the user' do
      expect(mail.to).to include(user.email)
    end

    it 'should come from no-reply@zooniverse.org' do
      expect(mail.from).to include('no-reply@zooniverse.org')
    end

    it 'should have the correct subject' do
      expect(mail.subject).to eq("We still need your help on the Zooniverse")
    end

    it 'should have the user name in the body' do
      expect(mail.body.encoded).to match(user.display_name)
    end

    it 'should contain a custom user unsubscribe notice' do
      unsubscribe_url = unsubscribe_url(token: user.unsubscribe_token)
      expect(mail.body).to include(unsubscribe_url)
    end

    it 'should contain google analytic campaign codes' do
      expect(mail.body).to include("?utm_source=Newsletter&utm_campaign=")
    end

    context "when the user has not classified before" do

      it 'should give a link to the main projects page' do
        expect(mail.body).to include("Check out the complete suite of projects here: https://zooniverse.org/projects")
      end

      it 'should be a general call to help' do
        expect(mail.body).to include("Our projects still need you!")
      end

    end

    context "when the user has user project preferences" do
      let(:user_project_preference) do
        create(:user_project_preference, user: user)
      end

      it 'should have the name of the users last classified project in the body' do
        last_project = user_project_preference.project
        expect(mail.body).to include(last_project.display_name)
      end

      it 'should have the url for the users last classified project in the body' do
        last_project = user_project_preference.project
        expect(mail.body).to include("https://www.zooniverse.org/projects/#{last_project.slug}")
      end

    end

  end
end
