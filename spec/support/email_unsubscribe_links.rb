require 'spec_helper'

shared_examples "email has a per user unsubscribe link" do

  it "should contain a per user unsubscribe link" do
    link_regex = /https?:\/\/panoptes_test.zooniverse.org\/unsubscribe\?token=.+/
    expect(mail.body.encoded).to match(link_regex)
  end
end

shared_examples "email generic unsubscribe links" do

  it "should contain a link to the user settings page" do
    link_regex = /https?:\/\/zooniverse.org\/#\/settings/
    expect(mail.body.encoded).to match(link_regex)
  end
end
