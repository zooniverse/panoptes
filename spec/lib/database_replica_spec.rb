# frozen_string_literal: true
require 'spec_helper'

describe DatabaseReplica do
  let(:flipper_key) { 'test_read_from_read_replica' }

  before do
    allow(Standby).to receive(:on_standby)
  end

  it 'defaults to reading from the primary db' do
    described_class.read(flipper_key) do
      User.count
    end
    expect(Standby).not_to have_received(:on_standby)
  end

  context 'with read replica feature flag on' do
    before do
      Panoptes.flipper.enable(flipper_key)
    end

    it 'uses standby gem to read from replica' do
      described_class.read(flipper_key) do
        User.count
      end
      expect(Standby).to have_received(:on_standby)
    end
  end
end
