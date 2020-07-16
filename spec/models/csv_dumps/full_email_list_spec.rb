require 'spec_helper'

describe CsvDumps::FullEmailList do
  let!(:all_email_user) { create(:user, global_email_communication: true, beta_email_communication: true, nasa_email_communication: true) }
  let!(:global_email_user) { create(:user, global_email_communication: true, beta_email_communication: false) }
  let!(:beta_email_user) { create(:user, global_email_communication: false, beta_email_communication: true) }
  let!(:nasa_email_user) { create(:user, global_email_communication: false, nasa_email_communication: true) }
  let!(:no_email_user) { create(:user, global_email_communication: false, beta_email_communication: false) }

  it 'returns global email list' do
    users = [all_email_user, global_email_user]
    list = described_class.new(:global)
    expect { |b| list.each(&b) }.to yield_successive_args(*users)
  end

  it 'returns beta email list' do
    users = [all_email_user, beta_email_user]
    list = described_class.new(:beta)
    expect { |b| list.each(&b) }.to yield_successive_args(*users)
  end

  it 'returns nasa email list' do
    users = [all_email_user, nasa_email_user]
    list = described_class.new(:nasa)
    expect { |b| list.each(&b) }.to yield_successive_args(*users)
  end

  it 'should handle matching string args ala sidekiq' do
    users = [all_email_user, global_email_user]
    list = described_class.new("global")
    expect { |b| list.each(&b) }.to yield_successive_args(*users)
  end
end
