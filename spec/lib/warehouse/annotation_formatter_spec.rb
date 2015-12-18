require 'spec_helper'

describe Warehouse::AnnotationFormatter do
  describe '.format' do
    let(:annotation) { double }
    let(:task_definition) { {'type': 'foobar'} }
    let(:translations) { double }

    it 'returns the formatted annotation' do
      formatted = double
      expect(Warehouse::BasicTaskFormatter).to receive(:format).with(annotation, task_definition: task_definition, translations: translations)
      described_class.format(annotation, task_definition: task_definition, translations: translations)
    end

    it 'returns an error annotation in case of exceptions' do
      allow(Warehouse::BasicTaskFormatter).to receive(:format).and_raise("FOO")
      formatted = described_class.format(annotation, task_definition: task_definition, translations: translations)
      expect(formatted).to eq(value: "ERROR PROCESSING ANNOTATION")
    end
  end

  describe '.formatter_class' do
    it 'returns the single task formatter' do
      expect(described_class.formatter_class('type' => 'single')).to eq(Warehouse::SingleTaskFormatter)
    end

    it 'returns the multiple task formatter' do
      expect(described_class.formatter_class('type' => 'multiple')).to eq(Warehouse::MultipleTaskFormatter)
    end

    it 'returns the drawing task formatter' do
      expect(described_class.formatter_class('type' => 'drawing')).to eq(Warehouse::DrawingTaskFormatter)
    end

    it 'returns the survey task formatter' do
      expect(described_class.formatter_class('type' => 'survey')).to eq(Warehouse::SurveyTaskFormatter)
    end

    it 'returns the text task formatter' do
      expect(described_class.formatter_class('type' => 'text')).to eq(Warehouse::TextTaskFormatter)
    end

    it 'returns the crop task formatter' do
      expect(described_class.formatter_class('type' => 'crop')).to eq(Warehouse::CropTaskFormatter)
    end

    it 'falls back to the basic task formatter' do
      expect(described_class.formatter_class('type' => 'foobar')).to eq(Warehouse::BasicTaskFormatter)
    end
  end
end
