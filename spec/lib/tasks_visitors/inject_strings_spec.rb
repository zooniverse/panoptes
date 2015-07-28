require 'spec_helper'

RSpec.describe TasksVisitors::InjectStrings do
  let(:task_hash) do
    {
      interest: {
        type: 'drawing',
        question: "interest.question",
        help: "interest.help",
        tools: [
          {value: 'red', label: "interest.tools.0.label", type: 'point', color: 'red'},
          {value: 'green', label: "interest.tools.1.label", type: 'point', color: 'lime'},
          {value: 'blue', label: "interest.tools.2.label", type: 'point', color: 'blue'}
        ],
        next: 'shape'
      },
      shape: {
        type: 'multiple',
        question: "shape.question",
        help: "old",
        answers: [
          {value: 'smooth', label: "shape.answers.0.label"},
          {value: 'features', label: "shape.answers.1.label"},
          {value: 'other', label: "shape.answers.2.label"}
        ],
        required: true,
        next: 'roundness'
      },
      roundness: {
        type: 'single',
        question: "roundness.question",
        answers: [
          {value: 'very', label: "roundness.answers.0.label", next: 'shape'},
          {value: 'sorta', label: "roundness.answers.1.label"},
          {value: 'not', label: "roundness.answers.2.label"}
        ],
        next: nil}
    }
  end

  describe "#visit" do
    let(:strings) do
      {
        "interest.question" => "q1",
        "interest.tools.0.label" => "l1",
        "interest.tools.1.label" => "l2",
        "interest.tools.2.label" => "l3",
        "shape.question" => "q2",
        "shape.answers.0.label" => "l4",
        "shape.answers.1.label" => "l5",
        "shape.answers.2.label" => "l6",
        "roundness.question" => "q3",
        "roundness.answers.0.label" => "l7",
        "roundness.answers.1.label" => "l8",
        "roundness.answers.2.label" => "l9",
        "interest.help" => 'help'
      }
    end

    before(:each) do
      TasksVisitors::InjectStrings.new(strings).visit(task_hash)
    end

    it 'should substitute question indexes with strings' do
      question_vals = task_hash.values_at(:interest, :shape, :roundness)
                      .map { |hash| hash[:question] }
      expect(question_vals).to eq(%w(q1 q2 q3))
    end

    it 'should substitute label indexes with strings' do
      label_vals = task_hash.values_at(:interest, :shape, :roundness)
                   .flat_map do |hash|
        if hash.has_key?(:answers)
          hash[:answers].map { |h| h[:label] }
        else
          hash[:tools].map { |h| h[:label] }
        end
      end

      expect(label_vals).to eq(%w(l1 l2 l3 l4 l5 l6 l7 l8 l9))
    end

    it 'should substitute help strings' do
      help_vals = task_hash.values_at(:interest, :shape, :roundness)
                      .map { |hash| hash[:help] }.compact
      expect(help_vals).to eq(%w(help old))
    end

    it 'should substitute a string at the correct index' do
      expect(task_hash[:interest][:question]).to eq("q1")
    end
  end
end
