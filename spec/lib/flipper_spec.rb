require 'spec_helper'

describe Flipper do

  describe 'feature flippin', :flipper_feat do
    let(:feature_name) { :test_feature }

    it "should not be enabled by default" do
      expect(Panoptes.flipper[feature_name].enabled?).to be_falsey
    end

    it "should enable features being turned on" do
      Panoptes.flipper[feature_name].enable
      expect(Panoptes.flipper[feature_name].enabled?).to be_truthy
    end
  end
end
