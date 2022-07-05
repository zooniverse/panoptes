require 'spec_helper'

describe Flipper do

  describe 'feature flippin' do
    let(:feature_name) { :test_feature }

    it "should not be enabled by default" do
      expect(Flipper.enabled?(feature_name)).to be_falsey
    end

    it "should enable features being turned on" do
      Flipper.enable(feature_name)
      expect(Flipper.enabled?(feature_name)).to be_truthy
    end
  end
end
