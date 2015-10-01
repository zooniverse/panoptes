require "spec_helper"

RSpec.describe Formatter::Csv::Subject do
  let(:project) { create(:project) }
  let(:workflow) { create(:workflow, project: project) }
  let(:subject_set) { create(:subject_set, project: project, workflows: [workflow]) }
  let(:loc_subject) do
    create(:subject, :with_mediums, project: project, uploader: project.owner)
  end
  let(:sms) { create(:set_member_subject, subject_set: subject_set, subject: loc_subject) }
  let!(:swc) do
    create :subject_workflow_count, classifications_count: 10, workflow: workflow,
      subject: loc_subject, retired_at: DateTime.now
  end

  def ordered_subject_locations
    {}.tap do |locs|
      Medium.all.order(:id).each_with_index.map do |m, index|
        locs[index] = m.get_url
      end
    end
  end

  let(:fields) do
    [loc_subject.id,
     project.id,
     [workflow.id].to_json,
     subject_set.id,
     ordered_subject_locations.to_json,
     loc_subject.metadata.to_json,
     {workflow.id => 10}.to_json,
     [workflow.id].to_json]
  end

  let(:header) do
    %w(subject_id project_id workflow_ids subject_set_id locations metadata classifications_by_workflow retired_in_workflow)
  end

  describe "::project_headers" do
    it 'should contain the required headers' do
      expect(described_class.headers).to match_array(header)
    end
  end

  describe "#to_array" do
    subject { described_class.new(project).to_array(sms) }

    it { is_expected.to match_array(fields) }
  end
end
