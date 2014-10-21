require 'spec_helper'

RSpec.describe TasksVisitors::InjectStrings do
  let(:task_hash) do
    {
     interest: {
                type: 'drawing',
                question: TasksVisitors::TaskIndex.new(0),
                tools: [
                        {value: 'red', label: TasksVisitors::TaskIndex.new(1), type: 'point', color: 'red'},
                        {value: 'green', label: TasksVisitors::TaskIndex.new(2), type: 'point', color: 'lime'},
                        {value: 'blue', label: TasksVisitors::TaskIndex.new(3), type: 'point', color: 'blue'}
                       ],
                next: 'shape'
               },
     shape: {
             type: 'multiple',
             question: TasksVisitors::TaskIndex.new(4),
             answers: [
                       {value: 'smooth', label: TasksVisitors::TaskIndex.new(5)},
                       {value: 'features', label: TasksVisitors::TaskIndex.new(6)},
                       {value: 'other', label: TasksVisitors::TaskIndex.new(7)}
                      ],
             required: true,
             next: 'roundness'
            },
     roundness: {
                 type: 'single',
                 question: TasksVisitors::TaskIndex.new(8),
                 answers: [
                           {value: 'very', label: TasksVisitors::TaskIndex.new(9), next: 'shape'},
                           {value: 'sorta', label: TasksVisitors::TaskIndex.new(10)},
                           {value: 'not', label: TasksVisitors::TaskIndex.new(11)}
                          ],
                 next: nil}
    }
  end

  describe "#visit" do
    let(:strings) { %w(q1 l1 l2 l3 q2 l4 l5 l6 q3 l7 l8 l9) }
    
    before(:each) do
      TasksVisitors::InjectStrings.new(strings).visit(task_hash)
    end
    
    it 'should substitute question TaskIndex objects with strings' do
      question_vals = task_hash.values_at(:interest, :shape, :roundness)
        .map { |hash| hash[:question] }
      expect(question_vals).to eq(%w(q1 q2 q3))
    end

    it 'should substitute label strings with TaskIndex objects' do
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

    it 'should substituted a string at the correct index' do
      expect(task_hash[:interest][:question]).to eq("q1")
    end
  end
end
