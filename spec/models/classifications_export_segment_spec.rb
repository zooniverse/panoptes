require 'spec_helper'

describe ClassificationsExportSegment do
  let(:workflow) { create :workflow }
  let(:subject) { create :subject, project: workflow.project }
  let(:classifications) { create_list :classification, 5, workflow: workflow, user: nil, subject_ids: [subject.id] }

  describe '#classifications_in_segment' do
    it 'returns completed classifications' do
      segment = described_class.new(workflow: workflow,
                                    first_classification: classifications[1],
                                    last_classification: classifications[-2])

      expect(segment.classifications_in_segment).to eq(classifications[1..-2])
    end
  end

  describe '#next_segment' do
    it 'builds a segment model for the next set of classifications' do
      segment = described_class.new(workflow: workflow,
                                    first_classification: classifications[0],
                                    last_classification: classifications[2])
      next_segment = segment.next_segment

      expect(next_segment.classifications_in_segment).to eq(classifications[3..-1])
    end
  end

  describe 'set_first_last_classifications' do
    it 'finds the remaining classifications after the given id' do
      segment = described_class.new(workflow: workflow)
      segment.set_first_last_classifications(classifications[1].id)

      expect(segment.first_classification_id).to eq(classifications[2].id)
      expect(segment.last_classification_id).to eq(classifications[4].id)
    end

    it 'sets first & last to nil if no classifications left' do
      segment = described_class.new(workflow: workflow)
      segment.set_first_last_classifications(classifications[4].id)

      expect(segment.first_classification_id).to be_nil
      expect(segment.last_classification_id).to be_nil
    end
  end
end
