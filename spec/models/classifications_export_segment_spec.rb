require 'spec_helper'

describe ClassificationsExportSegment do
  let(:workflow) { create :workflow }

  describe '#classifications_in_segment' do
    it 'returns completed classifications' do
      classifications = create_list :classification, 5, workflow: workflow
      segment = described_class.new(workflow: workflow,
                                    first_classification: classifications[1],
                                    last_classification: classifications[-2])

      expect(segment.classifications_in_segment).to eq(classifications[1..-2])
    end
  end

  describe '#next_segment'

  describe 'set_first_last_classification'
end
