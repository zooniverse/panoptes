require 'spec_helper'

describe Flipper do

  describe 'feature flippin' do
    let(:feature_name) { :test_feature }

    before do
      # Panoptes.flipper.remove(feature_name) once
      # https://github.com/jnunemaker/flipper/pull/126 is released
      feature = Panoptes.flipper[feature_name]
      feature.adapter.remove(feature)
    end

    it "should not be enabled by default" do
      expect(Panoptes.flipper[feature_name].enabled?).to be_falsey
    end

    it "should enable features being turned on" do
      Panoptes.flipper[feature_name].enable
      expect(Panoptes.flipper[feature_name].enabled?).to be_truthy
    end
  end
end
