require 'spec_helper'

RSpec.describe OrphanSubjectRemovalWorker do
  let!(:orphan) { create(:subject, :with_mediums) }
  let!(:non_orphan_ids) { create(:classification).subject_ids }

  it 'should remove the orphaned subjects' do
    orphan_id = orphan.id
    expect { subject.perform }.to change { Subject.count }.by(-1)
    expect { Subject.find(orphan_id) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'should remove the orphaned subjects media resources' do
    medium_ids = orphan.locations.map(&:id)
    subject.perform
    expect(Medium.where(id: medium_ids).count).to eq(0)
  end

  it 'should leave the non-orphan subject in place' do
    subject.perform
    expect { Subject.find(non_orphan_ids) }.not_to raise_error
  end
end
