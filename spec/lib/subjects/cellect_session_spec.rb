require "spec_helper"
require 'redis/namespace'

RSpec.describe Subjects::CellectSession do
  describe "#new" do
    it "should require both params" do
      expect{ described_class.new }.to raise_error(ArgumentError)
    end

    # it "should take a user and workflow ids as param" do
    #   expect{ described_class.new(1, 2) }.not_to raise_error
    # end

    it "should take a nil user id but set to unauth" do
      expect(described_class.new(nil, 2).user_id).to eq("unauth")
    end

    it "should raise an error on nil workflow id" do
      expect{ described_class.new(1, nil) }.to raise_error(
        Subjects::CellectSession::NilWorkflowError
      )
    end
  end

  describe "#host", :focus do
    let(:user_id) { 1 }
    let(:workflow_id) { 2 }
    let(:session) { described_class.new(user_id, workflow_id) }
    let(:cellect_key) { "pcs:#{user_id}:#{workflow_id}" }
    let(:host) { "http://test.com" }

    before(:each) do
      stub_cellect_connection
      allow(Cellect::Client).to receive(:choose_host).and_return(host)
      Sidekiq.redis { |conn| conn.flushdb }
    end

    context "when not set in redis" do
      it "should choose a new host" do
        expect(session).to receive(:choose_new_host)#.and_call_original
        session.host
      end

      it "should set it in redis with a TTL for reference later" do
        expect_any_instance_of(::Redis::Namespace).to receive(:setex)
          .with(cellect_key, 3600, host)#.and_call_original
        session.host
      end

      it "should return a host" do
        expect(session.host).to eq(host)
      end
    end

    context "when set in redis" do
      it "should return the host from redis" do
        expect_any_instance_of(::Redis::Namespace).to receive(:get)
          .with(cellect_key)
        session.host
      end
    end
  end
end
