require 'spec_helper'

describe RejectPatchRequests do
  let(:app) { double({ call: true }) }
  let(:middle) { RejectPatchRequests.new(app) }

  context "when a request is not a PATCH" do
    let(:env) { { 'REQUEST_METHOD' => 'PUT' } }

    it 'should allow execution to continue normally' do
      expect(app).to receive(:call)
      middle.call(env)
    end

    it 'should return true' do
      expect(middle.call(env)).to be true
    end
  end

  context "when a request is a PATCH" do
    let(:env) { { 'REQUEST_METHOD' => 'PATCH',
                  'PATH_INFO' => '/api/subjects' } }
    let(:request) { middle.call(env) }
    let(:status) { 501 }
    let(:msg) { "PATCH Requests are not currently supported" }

    it_behaves_like 'a json error response'
  end
end
