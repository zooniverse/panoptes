require 'spec_helper'

RSpec.describe TasksVisitors::ExtractStrings do
  let(:task_hash) do
    {
     interest: {
                type: 'drawing',
                question: 'Color some points',
                tools: [
                        {value: 'red', label: 'Red', type: 'point', color: 'red'},
                        {value: 'green', label: 'Green', type: 'point', color: 'lime'},
                        {value: 'blue', label: 'Blue', type: 'point', color: 'blue'}
                       ],
                next: 'shape'
               },
     shape: {
             type: 'multiple',
             question: 'What shape is this galaxy?',
             answers: [
                       {value: 'smooth', label: 'Smooth'},
                       {value: 'features', label: 'Features'},
                       {value: 'other', label: 'Star or artifact'}
                      ],
             required: true,
             next: 'roundness'
            },
     roundness: {
                 type: 'single',
                 question: 'How round is it?',
                 answers: [
                           {value: 'very', label: 'Very...', next: 'shape'},
                           {value: 'sorta', label: 'In between'},
                           {value: 'not', label: 'Cigar shaped'}
                          ],
                 next: nil}
    }
  end

  describe "#visit" do
    context "given an array collector" do
      let(:collector) { [] }
      
      before(:each) do
        subject.visit(task_hash, collector)
      end
      
      it 'should substitute question strings with TaskIndex objects' do
        question_vals = task_hash.values_at(:interest, :shape, :roundness)
          .map { |hash| hash[:question] }
        expect(question_vals).to all( be_a(TasksVisitors::TaskIndex))
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
        
        expect(label_vals).to all( be_a(TasksVisitors::TaskIndex))
      end

      it 'should set the index of the substituted string' do
        expect(task_hash[:interest][:question].index).to eq(0)
      end

      it 'should populate the collector with strings' do
        expect(collector).to include("Color some points",
                                     'Red',
                                     'How round is it?',
                                     "Cigar shaped")
      end
    end
  end
end
