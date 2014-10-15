require 'spec_helper'

RSpec.describe KafkaSerializer do
  let(:model) { create(:collection_with_subjects) }

  describe "#serialize" do
    let(:serialized) do
      KafkaSerializer.new([:name, :display_name], [:subjects, :owner])
        .serialize(model)
    end
    
    context "should produce a hash" do
      subject { serialized }

      it { is_expected.to have_key(:id) }
      it { is_expected.to have_key(:name) }
      it { is_expected.to have_key(:display_name) }
      it { is_expected.to have_key(:links) }
    end

    context "has required links" do
      subject { serialized[:links] }

      it { is_expected.to have_key(:subjects) }
      it { is_expected.to have_key(:owner) }
      it { is_expected.to have_key(:collection) }
    end

    it 'should include type of model in a polymorphic link' do
      expect(serialized[:links][:owner]).to eq({:type => 'user',
                                                :id => model.owner.id.to_s})
    end
    
  end

end
