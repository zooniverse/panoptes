require 'spec_helper'

RSpec.describe MediaStorage do
  describe "::adapter" do
    context "when passing arguments" do
      it 'should set a new adapter' do
        MediaStorage.instance_variable_set(:@adapter, nil)
        MediaStorage.adapter("test")
        expect(MediaStorage.adapter).to be_a(MediaStorage::TestAdapter)
      end
    end

    context "when not passing arguments" do
      context "when an adapter is set" do
        it 'should return the adapter' do
          MediaStorage.instance_variable_set(:@adapter, nil)
          MediaStorage.adapter("test")
          expect(MediaStorage.adapter).to be_a(MediaStorage::TestAdapter)
        end
      end

      context "when the adapter is not set" do
        it 'should raise a no media storage error' do
          MediaStorage.instance_variable_set(:@adapter, nil)
          expect{ MediaStorage.adapter }.to raise_error(MediaStorage::NoMediaStorage)
          MediaStorage.adapter("test")
        end
      end
    end
  end

  context "delegated actions" do
    let(:adapter) { double(stored_path: true, get_path: true, put_path: true) }

    before(:each) do
      allow(MediaStorage).to receive(:adapter).and_return(adapter)
    end

    describe "::stored_path" do
      it 'should call stored path on the adapter' do
        expect(adapter).to receive(:stored_path)
        MediaStorage.stored_path
      end
    end

    describe "::get_path" do
      it 'should call stored path on the adapter' do
        expect(adapter).to receive(:get_path)
        MediaStorage.get_path
      end
    end

    describe "::put_path" do
      it 'should call stored path on the adapter' do
        expect(adapter).to receive(:put_path)
        MediaStorage.put_path
      end
    end

    describe "::put_path" do
      it 'should call stored path on the adapter' do
        expect(adapter).to receive(:put_file)
        MediaStorage.put_file
      end
    end

    describe "::delete_path" do
      it 'should call stored path on the adapter' do
        expect(adapter).to receive(:delete_file)
        MediaStorage.delete_file
      end
    end
  end
end
