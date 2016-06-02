require 'spec_helper'

describe Flipper do

  describe 'feature flippin' do
    let(:feature) { :test_feature }

    it "should not be enabled by default" do
      expect(Panoptes.flipper[feature].enabled?).to be_falsey
    end

    it "should enable features being turned on" do
      Panoptes.flipper[feature].enable
      expect(Panoptes.flipper[feature].enabled?).to be_truthy
    end
  end
end
