require 'spec_helper'

RSpec.describe ClassificationsDumpWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:subject) { create(:subject, project: project, subject_sets: [create(:subject_set, workflows: [workflow])]) }
  let(:classifications) do
    create_list(:classification, 2, project: project, workflow: workflow, subjects: [subject])
  end

  describe "#perform" do
    it_behaves_like "dump worker", ClassificationDataMailerWorker, "project_classifications_export" do
      let(:num_entries) { classifications.size + 1 }
    end

    it_behaves_like 'rate limit dump worker'

    context "with standby read replica enabled" do
      before do
        Panoptes.flipper["dump_data_from_read_replica"].enable
      end

      it_behaves_like "dump worker", ClassificationDataMailerWorker, "project_classifications_export" do
        let(:num_entries) { classifications.size + 1 }
      end
    end

    context "with multi subject classification" do
      let(:second_subject) { create(:subject, project: project, subject_sets: subject.subject_sets) }
      let(:classifications) do
        [ create(:classification, project: project, workflow: workflow, subjects: [subject, second_subject]) ]
      end

      it_behaves_like "dump worker", ClassificationDataMailerWorker, "project_classifications_export" do
        let(:num_entries) { classifications.size + 1 }
      end
    end

    describe 'CachedExport resource storage' do
      let(:classification) do
        create(:classification, project: project, workflow: workflow, subjects: [subject])
      end

      it 'stores the processed export for next run' do

        expect { worker.perform(classification.project_id, 'project') }.to change(
          CachedExport,
          :count
        ).from(0).to(1)
      end

      it 'links the stored export to the classification' do
        worker.perform(classification.project_id, 'project')
        expect(classification.reload.cached_export).not_to be_nil
      end

      it 'does not try store one if one already exists' do
        create(:classification, project: project, workflow: workflow, subjects: [subject]) do |c|
          cached_export = create(:cached_export, resource: c)
          c.update_column(:cached_export_id, cached_export.id) # rubocop:disable Rails/SkipsModelValidations
        end
        expect { worker.perform(project.id, 'project') }.not_to change(CachedExport, :count)
      end
    end
  end
end
