require 'spec_helper'
require_relative '../../app/controllers/api/api_controller'

class FakeController
  attr_reader :request

  def initialize(filter)
    @filter = filter
  end

  def call(request)
    @request = ActionDispatch::Request.new(request)
    @filter.before(self)
    [200, {}, '']
  end
end

describe ContentTypeFilter do
  let(:filter) { ContentTypeFilter.new("application/json", 'text/plain', 'PATCH' => 'application/patch+json') }

  let(:request) do
    Rack::MockRequest.new(FakeController.new(filter))
  end


  describe '#before' do
    it 'should allow get requests' do
      expect{ request.get '' }.to_not raise_error
    end

    it 'should allow head requests' do
      expect{ request.head '' }.to_not raise_error
    end

    it 'should allow delete requests' do
      expect{ request.delete '' }.to_not raise_error
    end

    it 'should allow options requests' do
      expect{ request.request("OPTIONS") }.to_not raise_error
    end

    it 'should only allow a POST request with one of the specified content types' do
      expect{ request.post('', 'CONTENT_TYPE' => 'text/plain') }.to_not raise_error
      expect{ request.post('', 'CONTENT_TYPE' => 'application/json') }.to_not raise_error
    end

    it 'should raise an error on a PUT request without an included content type' do
      expect{ request.put('', 'CONTENT_TYPE' => 'text/html') }.to raise_error(Api::UnsupportedMediaType)
    end

    it 'should respect any overriden content types for a particular method' do
      expect{ request.patch('', 'CONTENT_TYPE' => 'application/patch+json') }.to_not raise_error
      expect{ request.patch('', 'CONTENT_TYPE' => 'application/json') }.to raise_error(Api::UnsupportedMediaType)
    end
  end
end
