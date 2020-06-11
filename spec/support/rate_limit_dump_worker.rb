# frozen_string_literal: true

RSpec.shared_examples 'rate limit dump worker' do
  let(:enabled_lambda) do
    described_class.sidekiq_options.dig('congestion', :enabled)
  end
  let(:user_double) { instance_double(User) }

  before do
    allow(User).to receive(:find).and_return(user_double)
  end

  it 'enables congestion for non-admin requesters' do
    allow(user_double).to receive(:is_admin?).and_return(false)
    expect(enabled_lambda.call(nil, nil, nil, 1)).to eq(true)
  end

  it 'disables congestion if no requester_id is passed' do
    expect(enabled_lambda.call(nil, nil, nil, nil)).to eq(false)
  end

  it 'disables congestion for admin requesters' do
    allow(user_double).to receive(:is_admin?).and_return(true)
    expect(enabled_lambda.call(nil, nil, nil, 1)).to eq(false)
  end

  describe 'skip congestions for special requester ids' do
    it 'handles no configured skip ids' do
      allow(user_double).to receive(:is_admin?).and_return(false)
      expect(enabled_lambda.call(nil, nil, nil, 23)).to eq(true)
    end

    it 'disables congestion if matching skip ids' do
      ENV['SKIP_DUMP_RATE_LIMIT_USER_IDS'] = '1,2,23,55'
      expect(enabled_lambda.call(nil, nil, nil, 23)).to eq(false)
      ENV.delete('SKIP_DUMP_RATE_LIMIT_USER_IDS')
    end

    it 'handles spaces in skip id inputs' do
      ENV['SKIP_DUMP_RATE_LIMIT_USER_IDS'] = '23,   55'
      expect(enabled_lambda.call(nil, nil, nil, 55)).to eq(false)
      ENV.delete('SKIP_DUMP_RATE_LIMIT_USER_IDS')
    end
  end
end
