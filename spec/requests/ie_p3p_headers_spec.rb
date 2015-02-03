require 'spec_helper'

#Taken from: https://github.com/carrot/p3p/blob/1d69a1e3c254667e18ee9a553d0ee6fda2592c12/spec/middleware_spec.rb
describe "IE p3p headers", type: :request do

  shared_examples 'it returns P3P headers' do |http_verb|
    it "should return default P3P headers in the case of a #{http_verb} request" do
      p3p_header = Time.now.to_i
      P3P.configure { |c| c.header = p3p_header }
      get root_path
      expect(response.headers["P3P"]).to eq(p3p_header)
    end
   end

  describe P3P::Middleware do
    after do
      P3P.configuration.set_default_header!
    end

    it_should_behave_like 'it returns P3P headers', 'GET'
    it_should_behave_like 'it returns P3P headers', 'POST'
    it_should_behave_like 'it returns P3P headers', 'PUT'
    it_should_behave_like 'it returns P3P headers', 'DELETE'
    it_should_behave_like 'it returns P3P headers', 'HEAD'
    it_should_behave_like 'it returns P3P headers', 'OPTIONS'
    it_should_behave_like 'it returns P3P headers', 'TRACE'
    it_should_behave_like 'it returns P3P headers', 'CONNECT'
  end
end
