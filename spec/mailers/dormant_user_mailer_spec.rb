require "spec_helper"


RSpec.describe DormantUserMailer, :type => :mailer do
  let(:user) { create(:user) }
  let(:mail) { DormantUserMailer.email_dormant_user(user)}

  describe "#dormant_user_email" do

    it 'should mail the user' do
      expect(mail.to).to include(user.email)
    end

    it 'should come from no-reply@zooniverse.org' do
      expect(mail.from).to include('no-reply@zooniverse.org')
    end

    it 'should have the correct subject' do
      expect(mail.subject).to eq("Come back to the Zooniverse")
    end

    it 'should have the user name in the body' do
      expect(mail.body.encoded).to match("#{user.display_name}")
    end

    context "when the user has user project preferences" do
      let(:classification) do
          create(:classification, user: user)
        end

        before do
          ClassificationLifecycle.perform(classification, "create")
        end

        it 'should have the name of the users last classified project in the body' do
          last_project = UserProjectPreference.where(
            user_id: user.id,
            project_id: classification.project_id
            ).first
          binding.pry
          expect(mail.body).to include(last_project)
        end
    end

  end
end
