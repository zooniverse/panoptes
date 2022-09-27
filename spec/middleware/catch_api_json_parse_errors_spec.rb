# frozen_string_literal: true

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

  let(:middle) { described_class.new(app) }

  context 'when call does not error' do
    it 'returns true' do
      expect(middle.call(good_env)).to be true
    end
  end

  context 'when call errors with a StandardError' do
    before do
      allow(app).to receive(:call).and_raise(StandardError)
    end

    it 'allows the error to propogate' do
      expect { middle.call(good_env) }.to raise_error(StandardError)
    end
  end

  context 'when call errors with ParseError' do
    let(:error) {
      # raise an error here to simulate the HTTP request data parsers blowing up
      # https://github.com/rails/rails/commit/b3d41eae4b138d6c9d38bd9c1cbe033802c0e21d
      # to match the deprecated params parsing error behaviour
      # via last know error $! (https://til.hashrocket.com/posts/da62981e47-ruby-)
      begin
        # this would really be a specific parser error in reality, e.g. a `JSON::ParserError` error
        raise StandardError
      rescue StandardError
        return ActionDispatch::ParamsParser::ParseError.new
      end
    }

    before do
      allow(app).to receive(:call).and_raise(error)
    end

    context 'when the call is not JSON' do
      it 'reraises the error' do
        expect { middle.call(bad_env) }.to raise_error(ActionDispatch::ParamsParser::ParseError)
      end
    end

    context 'when the call is JSON' do
      let(:request) { middle.call(good_env) }
      let(:status) { 400 }
      let(:msg) { /There was a problem in the JSON you submitted/ }

      it_behaves_like 'a json error response'
    end
  end
end
