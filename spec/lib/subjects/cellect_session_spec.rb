require "spec_helper"
require 'redis/namespace'

RSpec.describe Subjects::CellectSession do
  let(:user_id) { 1 }
  let(:workflow_id) { 2 }
  let(:session) { described_class.new(user_id, workflow_id) }
  let(:cellect_key) { "pcs:#{user_id}:#{workflow_id}" }
  let(:host) { "http://test.com" }
  let(:redis) { stubbed_redis_connection }
  let(:get_host) { nil }

  before(:each) do
    stub_cellect_connection
    stub_redis_connection(get_host)
    allow(Cellect::Client).to receive(:choose_host).and_return(host)
  end

  describe "#new" do
    it "should require both params" do
      expect{ described_class.new }.to raise_error(ArgumentError)
    end

    it "should take a nil user id but set to unauth" do
      expect(described_class.new(nil, 2).user_id).to eq("unauth")
    end

    it "should raise an error on nil workflow id" do
      expect{ described_class.new(1, nil) }.to raise_error(
        Subjects::CellectSession::NilWorkflowError,
        "Nil workflow passed to cellect session"
      )
    end
  end

  describe "#host" do
    context "when not set in redis" do
      it "should choose a new host" do
        expect(session).to receive(:cellect_host).and_call_original
        session.host
      end

      it "should set it in redis with a TTL for reference later" do
        expect(redis).to receive(:setex).with(cellect_key, 3600, host)
        session.host
      end

      it "should return a host" do
        expect(session.host).to eq(host)
      end

      it "should allow the ttl to be set" do
        ttl = 60
        expect(redis).to receive(:setex).with(cellect_key, ttl, host)
        session.host(ttl)
      end
    end

    context "when set in redis" do
      let(:get_host) { host }

      it "should return the host from redis" do
        expect(redis).to receive(:get).with(cellect_key)
        session.host
      end

      it "should check the host is still alive" do
        expect(Cellect::Client).to receive(:host_exists?).with(host)
        session.host
      end

      context "when the host is not available anymore" do
        it "should reset the host" do
          allow(Cellect::Client).to receive(:host_exists?).with(host).and_return(false)
          expect(session).to receive(:reset_host)
          session.host
        end
      end
    end
  end

  describe "#reset_host" do

    it "should choose a new host" do
      expect(session).to receive(:cellect_host).and_call_original
      session.reset_host
    end

    it "should set it in redis with a TTL for reference later" do
      expect(redis).to receive(:setex).with(cellect_key, 3600, host)
      session.reset_host
    end

    it "should allow the ttl to be set" do
      ttl = 60
      expect(redis).to receive(:setex).with(cellect_key, ttl, host)
      session.reset_host(ttl)
    end

    context "when there are no hosts to cellect from" do

      it "should should raise an error" do
        allow(Cellect::Client).to receive(:choose_host).and_return(nil)
        expect {
          session.reset_host
        }.to raise_error(
          Subjects::CellectSession::NoHostError,
          "No cellect host available"
        )
      end
    end
  end
end
