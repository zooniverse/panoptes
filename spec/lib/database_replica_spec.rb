# frozen_string_literal: true

require 'spec_helper'

describe DatabaseReplica do
  let(:flipper_key) { :test_read_from_read_replica }

  before do
    allow(Standby).to receive(:on_standby).and_call_original
  end

  describe '::read' do
    it 'defaults to reading from the primary db' do
      described_class.read(flipper_key) { nil }
      expect(Standby).not_to have_received(:on_standby)
    end

    context 'with read replica feature flag on' do
      before do
        Flipper.enable(flipper_key)
      end

      it 'uses standby gem to read from replica' do
        described_class.read(flipper_key) { nil }
        expect(Standby).to have_received(:on_standby)
      end
    end
  end

  describe '::read_without_timeout' do
    let(:pg_statment_timeout) { Panoptes.pg_statement_timeout }
    let(:default_set_timeout) { "SET statement_timeout = #{pg_statment_timeout}" }
    let(:no_timeout) { 'SET statement_timeout = 0' }
    let(:connection_double) do
      connection_double = instance_double('ActiveRecord::ConnectionAdapters::PostgreSQLAdapter')
      allow(connection_double).to receive(:execute)
      connection_double
    end
    let(:flipper_enabled_state) { false }

    before do
      # stub flipper here to avoid hitting the AR connection double we've got setup
      allow(Flipper).to receive(:enabled?).with(flipper_key).and_return(flipper_enabled_state)
    end

    it 'defaults to reading from the primary db' do
      described_class.read_without_timeout(flipper_key) { nil }
      expect(Standby).not_to have_received(:on_standby)
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'sets the connection to not timeout and resets to default' do
      allow(ActiveRecord::Base).to receive(:connection).and_return(connection_double)
      described_class.read_without_timeout(flipper_key) { nil }

      expect(connection_double).to have_received(:execute).with(no_timeout).ordered
      expect(connection_double).to have_received(:execute).with(default_set_timeout).ordered
    end
    # rubocop:enable RSpec/MultipleExpectations

    context 'with read replica feature flag on' do
      let(:flipper_enabled_state) { true }

      it 'uses standby gem to read from replica' do
        described_class.read_without_timeout(flipper_key) { nil }
        expect(Standby).to have_received(:on_standby)
      end

      # rubocop:disable RSpec/MultipleExpectations
      it 'sets the connection to not timeout and resets to default' do
        allow(ActiveRecord::Base).to receive(:connection).and_return(connection_double)
        described_class.read_without_timeout(flipper_key) { nil }

        expect(connection_double).to have_received(:execute).with(no_timeout).ordered
        expect(connection_double).to have_received(:execute).with(default_set_timeout).ordered
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end
end
