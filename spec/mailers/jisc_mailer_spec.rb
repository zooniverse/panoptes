require "spec_helper"

RSpec.describe JiscMailer, :type => :mailer do
  let(:user) { create(:user) }

  describe "::subscribe" do
    context "with a configured password" do
      let(:mail) { JiscMailer.subscribe(user.email) }

      it 'should mail the listserv' do
        expect(mail.to).to include("listserv@jiscmail.ac.uk")
      end

      it 'should come from no-reply@zooniverse.org' do
        expect(mail.from).to include("no-reply@zooniverse.org")
      end

      it 'should have the subscribe command' do
        expect(mail.body.encoded).to eq("quiet add zooniverse #{ user.email } * PW=test_password\r\n\r\n")
      end
    end

    context "without a configured password" do
      it 'should raise an error' do
        allow(Panoptes).to receive(:jisc_mail_config).and_return({})
        expect do
          JiscMailer.subscribe(user.email).deliver
        end.to raise_error("JISC Mail password required")
      end
    end
  end

  describe "::unsubscribe" do
    context "with a configured password" do
      let(:mail) { JiscMailer.unsubscribe(user.email) }

      it 'should mail the listserv' do
        expect(mail.to).to include("listserv@jiscmail.ac.uk")
      end

      it 'should come from no-reply@zooniverse.org' do
        expect(mail.from).to include("no-reply@zooniverse.org")
      end

      it 'should have the subscribe command' do
        expect(mail.body.encoded).to eq("quiet del zooniverse #{ user.email } PW=test_password\r\n\r\n")
      end
    end

    context "without a configured password" do
      it 'should raise an error' do
        allow(Panoptes).to receive(:jisc_mail_config).and_return({})
        expect { JiscMailer.unsubscribe(user.email).deliver }.to raise_error("JISC Mail password required")
      end
    end
  end
end
