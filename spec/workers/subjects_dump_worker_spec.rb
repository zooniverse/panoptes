# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubjectsDumpWorker do
  let(:worker) { described_class.new }
  let(:project) { create(:project) }
  let(:workflow) { create(:workflow_with_subjects, num_sets: 1, project: project) }
  let(:unlinked_subject_set) { create(:subject_set, project: project)}
  let!(:subjects) do
    create_list(:set_member_subject, 2, subject_set: unlinked_subject_set).map(&:subject)
  end
  let(:num_subjects) { unlinked_subject_set.subjects.count + workflow.subjects.count }

  describe '#perform' do
    it_behaves_like 'dump worker', SubjectDataMailerWorker, 'project_subjects_export' do
      let(:num_entries) { num_subjects + 1 }
    end
  end

  describe 'cache wiring' do
    let(:shared_cache) { SubjectDumpCache.new }

    before do
      allow(CsvDumps::FindsDumpResource).to receive(:find).and_return(project)
      medium_instance = instance_double(Medium)
      finds_medium_instance = instance_double(CsvDumps::FindsMedium, medium: medium_instance)
      allow(CsvDumps::FindsMedium).to receive(:new).and_return(finds_medium_instance)
      allow(DumpMailer).to receive(:new).and_return(instance_double(DumpMailer, send_email: true))
      allow_any_instance_of(CsvDumps::DumpProcessor).to receive(:execute).and_return(true)

      allow(worker).to receive(:cache).and_return(shared_cache)
      allow(Formatter::Csv::Subject).to receive(:new).and_call_original
      allow(CsvDumps::SubjectScope).to receive(:new).and_call_original

      worker.perform(project.id, 'project')
    end

    it 'passes a shared cache to the formatter' do
      expect(Formatter::Csv::Subject).to have_received(:new).with(project, shared_cache)
    end

    it 'passes a shared cache to the scope' do
      expect(CsvDumps::SubjectScope).to have_received(:new).with(project, shared_cache)
    end
  end
end
