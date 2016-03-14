require "spec_helper"

RSpec.describe Subjects::CellectClient do
  let(:cellect_host) { 'example.com' }
  before(:each) do
    stub_cellect_connection
    stub_redis_connection
  end

  def raise_error_for(method, times=1)
    counter = 0
    allow(Cellect::Client.connection).to receive(method) do
      (counter += 1) <= times ? raise(StandardError) : true
    end
  end

  describe "#add_seen" do
    it 'should call the method on the cellect client' do
      expect(Cellect::Client.connection).to receive(:add_seen)
                                             .with(host: cellect_host,
                                                   workflow_id: 1,
                                                   user_id: 2,
                                                   subject_id: 4)
      Subjects::CellectClient.add_seen(1, 2, 4)
    end

    it 'should try a new host if the first request fails' do
      raise_error_for(:add_seen)
      expect(Cellect::Client.connection).to receive(:add_seen)
                                             .with(host: cellect_host,
                                                   workflow_id: 1,
                                                   user_id: 2,
                                                   subject_id: 4)
      Subjects::CellectClient.add_seen(1, 2, 4)
    end

    it 'should only retry once' do
      raise_error_for(:add_seen, 2)
      expect do
        Subjects::CellectClient.add_seen(1, 2, 4)
      end.to raise_error(
        Subjects::CellectClient::ConnectionError,
        "Cellect can't reach the server"
      )
    end
  end

  describe "#load_user" do
    it 'should call the method on the cellect client' do
      expect(Cellect::Client.connection).to receive(:load_user)
                                             .with(host: cellect_host,
                                                   workflow_id: 1,
                                                   user_id: 2)
      Subjects::CellectClient.load_user(1, 2)
    end

    it 'should try a new host if the first request fails' do
      counter = 0
      allow(Cellect::Client.connection).to receive(:load_user) do
        (counter += 1) == 1 ? raise(StandardError) : true
      end

      expect(Cellect::Client.connection).to receive(:load_user)
                                             .with(host: cellect_host,
                                                   workflow_id: 1,
                                                   user_id: 2)
      Subjects::CellectClient.load_user(1, 2)
    end

    it 'should retry four times' do
      counter = 0
      allow(Cellect::Client.connection).to receive(:load_user) do
        (counter += 1) < 4 ? raise(StandardError) : true
      end
      Subjects::CellectClient.load_user(1, 2)
      expect(counter).to eq(4)
    end
  end

  describe "#remove_subject" do
    it 'should call the method on the cellect client' do
      expect(Cellect::Client.connection).to receive(:remove_subject)
                                             .with(1,
                                                   workflow_id: 2,
                                                   group_id: 4)
      Subjects::CellectClient.remove_subject(1, 2, 4)
    end

    it 'should try a new host if the first request fails' do
      counter = 0
      allow(Cellect::Client.connection).to receive(:remove_subject) do
        (counter += 1) == 1 ? raise(StandardError) : true
      end
      expect(Cellect::Client.connection).to receive(:remove_subject)
                                             .with(1,
                                                   workflow_id: 2,
                                                   group_id: 4)
      Subjects::CellectClient.remove_subject(1, 2, 4)
    end
  end

  describe "#get_subjects" do
    it 'should call the method on the cellect client' do
      expect(Cellect::Client.connection).to receive(:get_subjects)
                                             .with(host: cellect_host,
                                                   workflow_id: 1,
                                                   user_id: 2,
                                                   group_id: nil,
                                                   limit: 4)
      Subjects::CellectClient.get_subjects(1, 2, nil, 4)
    end

    it 'should try a new host if the first request fails' do
      counter = 0
      allow(Cellect::Client.connection).to receive(:get_subjects) do
        (counter += 1) == 1 ? raise(StandardError) : true
      end
      expect(Cellect::Client.connection).to receive(:get_subjects)
                                             .with(host: cellect_host,
                                                   workflow_id: 1,
                                                   user_id: 2,
                                                   group_id: nil,
                                                   limit: 4)
      Subjects::CellectClient.get_subjects(1, 2, nil, 4)
    end

    #applies to all RequestToHost methods
    context "when cellect session cant choose a host due to redis error" do
      it 'should raise a connection error' do
        allow_any_instance_of(Subjects::CellectSession)
          .to receive(:host)
          .and_raise(Redis::CannotConnectError)
        expect do
          Subjects::CellectClient.get_subjects(1, 2, nil, 4)
        end.to raise_error(
          Subjects::CellectClient::ConnectionError,
         "Cellect can't find a server host"
        )
      end
    end

    #applies to all RequestToHost methods
    context "when cellect session raises no host error" do
      it 'should raise a connection error' do
        allow_any_instance_of(Subjects::CellectSession)
          .to receive(:host)
          .and_raise(Subjects::CellectSession::NoHostError)
        expect do
          Subjects::CellectClient.get_subjects(1, 2, nil, 4)
        end.to raise_error(
          Subjects::CellectClient::ConnectionError,
         "Cellect can't find a server host"
        )
      end
    end
  end

  describe "::reload_workflow" do
    it 'should call the method on the cellect client' do
      expect(Cellect::Client.connection).to receive(:reload_workflow).with(1)
      Subjects::CellectClient.reload_workflow(1)
    end
  end
end
