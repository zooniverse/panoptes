require 'spec_helper'

describe CatchApiJsonParseErrors do
  let(:app) { double({ call: true }) }
  let(:good_env) do
    {
     'CONTENT_TYPE' => 'application/json; charset=utf-8',
     'HTTP_ACCEPT' => 'application/vnd.api+json; version=1'
    }
  end

  let(:bad_env) do
    {
     'CONTENT_TYPE' => 'text/plain; charset=utf-8',
     'HTTP_ACCEPT' => 'application/vnd.api+json; version=1'
    }
  end

  let(:middle) { CatchApiJsonParseErrors.new(app) }

  context "call does not error" do
    it 'should return true' do
      expect(middle.call(good_env)).to be true
    end
  end

  context "call errors with a StandardError" do
    before(:each) do
      allow(app).to receive(:call).and_raise(StandardError)
    end

    it 'should allow the error to propogate' do
      expect{ middle.call(good_env) }.to raise_error(StandardError)
    end
  end

  context "call errors with ParseError" do
    let(:error) { ActionDispatch::ParamsParser::ParseError.new('test', 'test') }

    before(:each) do
      allow(app).to receive(:call).and_raise(error)
    end

    context "when the call is not JSON" do
      it 'should reraise the error' do
        expect{ middle.call(bad_env) }.to raise_error(ActionDispatch::ParamsParser::ParseError)
      end
    end

    context "when the call is JSON" do
      let(:request) {  middle.call(good_env) }
      let(:status) { 400 }
      let(:msg) { /There was a problem in the JSON you submitted/ }

      it_behaves_like 'a json error response'
    end
  end

  context "call errors with JSON::ParserError" do
    let(:error) { JSON::ParserError.new('test') }

    before(:each) do
      allow(app).to receive(:call).and_raise(error)
    end

    let(:request) {  middle.call(good_env) }
    let(:status) { 400 }
    let(:msg) { /There was a problem in the JSON you submitted/ }

    it_behaves_like 'a json error response'
  end
end
