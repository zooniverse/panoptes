# frozen_string_literal: true
require 'spec_helper'

describe DatabaseReplica do
  let(:flipper_key) { 'test_read_from_read_replica' }
  let(:connection_double) do
    connection_double = instance_double('ActiveRecord::ConnectionAdapters::PostgreSQLAdapter')
    allow(connection_double).to receive(:execute)
    connection_double
  end
  let(:pg_statment_timeout) { Panoptes.pg_statement_timeout }
  let(:default_set_timeout) { "SET statement_timeout = #{pg_statment_timeout}" }
  let(:double_set_timeout) { "SET statement_timeout = #{(pg_statment_timeout * 2).to_i}" }

  before do
    allow(Standby).to receive(:on_standby)
  end

  it 'defaults to reading from the primary db' do
    described_class.read(flipper_key) do
      User.count
    end
    expect(Standby).not_to have_received(:on_standby)
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'sets the pg statement timeouts to allow long running dump queries' do
    allow(ActiveRecord::Base).to receive(:connection).and_return(connection_double)
    described_class.read(flipper_key) { nil }

    expect(connection_double).to have_received(:execute).with(double_set_timeout).ordered
    expect(connection_double).to have_received(:execute).with(default_set_timeout).ordered
  end
  # rubocop:enable RSpec/MultipleExpectations

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
