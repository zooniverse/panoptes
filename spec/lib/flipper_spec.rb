require 'spec_helper'

describe Flipper do

  describe 'feature flippin' do
    let(:feature_name) { :test_feature }

    it 'does not enable by default' do
      expect(described_class.enabled?(feature_name)).to be(false)
    end

    it 'allows features to be turned on' do
      described_class.enable(feature_name)
      expect(described_class.enabled?(feature_name)).to be(true)
    end
  end
end
