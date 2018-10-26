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

  describe "#to_rows" do
    let(:sms) { create(:set_member_subject, subject_set: subject_set, subject: subject) }
    let(:retirement_date) { Time.zone.now.change(usec: 0) }

    before do
      sms
      create(:subject_workflow_status, classifications_count: 10, workflow: workflow,
        subject: subject, retired_at: retirement_date)
      create(:subject_workflow_status, classifications_count: 5, workflow: workflow_two,
        subject: subject)
    end

    let(:workflow_one_row) do
      {
        subject_id: subject.id,
        project_id: project.id,
        workflow_id: workflow.id,
        subject_set_id: subject_set.id,
        metadata: subject.metadata.to_json,
        locations: ordered_subject_locations.to_json,
        classifications_count: 10,
        retired_at: retirement_date,
        retirement_reason: nil,
        created_at: subject.created_at,
        updated_at: subject.updated_at
      }
    end

    let(:workflow_two_row) do
      {
        subject_id: subject.id,
        project_id: project.id,
        workflow_id: workflow_two.id,
        subject_set_id: subject_set.id,
        metadata: subject.metadata.to_json,
        locations: ordered_subject_locations.to_json,
        classifications_count: 5,
        retired_at: nil,
        retirement_reason: nil,
        created_at: subject.created_at,
        updated_at: subject.updated_at
      }
    end

    let(:expected) { [workflow_one_row.values, workflow_two_row.values] }

    let(:result) { described_class.new(project).to_rows(subject) }

    it "should match the expected output" do
      expect(result).to match_array(expected)
    end

    context "with an old unlinked subject" do
      let(:subject_set_ids) { [ ] }
      let(:empty_attrs) do
        {
          subject_set_id: nil,
          workflow_id: nil,
          classifications_count: 0,
          retired_at: nil,
          retirement_reason: nil
        }
      end
      let(:expected) do
        [ workflow_one_row.merge(empty_attrs).values ]
      end

      it "should match the expected output" do
        sms.destroy
        subject.reload
        expect(result).to match_array(expected)
      end
    end

    context "with a subject that has no location metadata" do
      it "should match the db ordered subject_locations array" do
        allow_any_instance_of(Medium::ActiveRecord_Associations_CollectionProxy)
          .to receive(:loaded?)
          .and_return(true)
        allow_any_instance_of(Medium).to receive(:metadata).and_return(nil)
        expect(result).to match_array(expected)
      end
    end

    describe "on reuse of the formatter for the next subject" do
      let(:next_subject) do
        create(:subject, :with_mediums, project: project, uploader: project.owner)
      end
      let(:formatter) { described_class.new(project) }

      before do
        create(:set_member_subject, subject_set: subject_set, subject: next_subject)
      end

      it "should not memoize any data and have 0 counts on the second run" do
        first_result = formatter.to_rows(subject)
        second_result = formatter.to_rows(next_subject)
        classification_counts = second_result.map { |result| result[6] }
        expect(classification_counts).to match_array([0,0])
      end
    end

    context "when in another set that is not linked to a workflow" do
      let(:not_linked_set) do
        create(:subject_set, project: project, num_workflows: 0)
      end
      let(:non_linked_subject) do
        {
          subject_id: subject.id,
          project_id: project.id,
          workflow_id: nil,
          subject_set_id: not_linked_set.id,
          metadata: subject.metadata.to_json,
          locations: ordered_subject_locations.to_json,
          classifications_count: 0,
          retired_at: nil,
          retirement_reason: nil,
          created_at: subject.created_at,
          updated_at: subject.updated_at
        }
      end

      it "should export a third row for the non-linked set" do
        subject.subject_sets << not_linked_set
        expect(result).to match_array(expected | [ non_linked_subject.values ])
      end
    end
  end
end
