require 'spec_helper'

describe ClassificationsDump do
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:subject) { create(:subject, project: project, subject_sets: [create(:subject_set, workflows: [workflow])]) }
  let(:output) { [] }
  let(:dump) { described_class.new(project) }

  it 'returns a header row' do
    dump.write_to(output)
    expect(output.size).to eq(1)
  end

  it 'returns rows for all matching classifications' do
    classifications = create_list(:classification, 5, project: project, workflow: workflow, subjects: [subject])
    dump.write_to(output)
    expect(output.map(&:first)).to match_array(["classification_id"] + classifications.map(&:id))
  end

  it "does not return classifications with workflows that don't exist" do
    classifications = create_list(:classification, 5, project: project, workflow: workflow, subjects: [subject])
    classifications.last.update_column(:workflow_id, Workflow.last.id+1)
    dump.write_to(output)
    expect(output.map(&:first)).to match_array(["classification_id"] + classifications[0..-2].map(&:id))
  end

  it 'should find only the classifications within the date range' do
    dump = described_class.new(project, date_range: Date.new(2015, 1, 1)..Date.new(2015, 1, 31))
    classifications = create_list(:classification, 5, project: project, workflow: workflow, subjects: [subject], created_at: Time.local(2015, 1, 2))
    classifications.last.update_column(:created_at, Time.local(2015, 2, 3))
    dump.write_to(output)
    expect(output.map(&:first)).to match_array(["classification_id"] + classifications[0..-2].map(&:id))
  end
end
