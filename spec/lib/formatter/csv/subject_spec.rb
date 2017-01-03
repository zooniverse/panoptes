require "spec_helper"

RSpec.describe Formatter::Csv::Subject do
  let(:project) { create(:project) }
  let(:workflow) { create(:workflow, project: project) }
  let(:workflow_two) { create(:workflow, project: project) }
  let(:subject_set) { create(:subject_set, project: project, workflows: [workflow]) }
  let(:subject) do
    create(:subject, :with_mediums, project: project, uploader: project.owner)
  end
  let(:subject_set_ids) { [ subject_set.id ] }
  let(:ordered_subject_locations) do
    {}.tap do |locs|
      subject.ordered_locations.each_with_index.map do |m, index|
        locs[index] = m.get_url
      end
    end
  end

  let(:header) do
    %w(subject_id project_id workflow_ids subject_set_ids metadata locations classifications_by_workflow retired_in_workflow)
  end

  describe "::project_headers" do
    it 'should contain the required headers' do
      expect(described_class.headers).to match_array(header)
    end
  end

  describe "#to_array" do
    let(:sms) { create(:set_member_subject, subject_set: subject_set, subject: subject) }
    before do
      sms
      create(:subject_workflow_status, classifications_count: 10, workflow: workflow,
        subject: subject, retired_at: DateTime.now)
      create(:subject_workflow_status, classifications_count: 5, workflow: workflow_two,
        subject: subject)
    end

    let(:fields) do
      [subject.id,
       project.id,
       [workflow.id, workflow_two.id].to_json,
       subject_set_ids.to_json,
       subject.metadata.to_json,
       ordered_subject_locations.to_json,
       {workflow.id => 10, workflow_two.id => 5}.to_json,
       [workflow.id].to_json]
    end
    let(:result) { described_class.new(project, subject).to_array }

    it "should match the expected output" do
      expect(result).to match_array(fields)
    end

    context "with an old unlinked subject" do
      let(:subject_set_ids) { [ ] }

      it "should match the expected output" do
        sms.destroy
        subject.reload
        expect(result).to match_array(fields)
      end
    end

    context "with a subject that has no location metadata" do

      it "should match the db ordered subject_locations array" do
        allow_any_instance_of(Medium::ActiveRecord_Associations_CollectionProxy)
          .to receive(:loaded?)
          .and_return(true)
        allow_any_instance_of(Medium).to receive(:metadata).and_return(nil)
        expect(result).to match_array(fields)
      end
    end
  end
end
