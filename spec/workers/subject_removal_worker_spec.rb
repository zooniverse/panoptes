require 'spec_helper'

RSpec.describe SubjectRemovalWorker do
  let(:subject_id) { 1 }
  let(:feature_name) { "remove_orphan_subjects" }
  let(:remover) { instance_double(Subjects::Remover) }

  describe 'flipper enabled' do
    let(:project) { create(:project) }
    let!(:subjects) { create_list(:subject, 2) }
    let!(:subject_set) { create(:subject_set, project: project) }
    let!(:set_member_subject) { create(:set_member_subject, subject: subjects.last, subject_set: subject_set) }

    before do
      Flipper.enable(feature_name)
    end

    context 'orphan remover cleanup function' do
      it 'should call the orphan remover cleanup when enabled' do
        expect(Subjects::Remover).to receive(:new).with(subject_id).and_return(remover)
        expect(remover).to receive(:cleanup)
        subject.perform(subject_id)
      end
    end

    context 'deleting subjects' do
      it 'deletes subject not associated with set_member_subject' do
        subject.perform(subjects.first.id)
        expect(Subject.exists?(subjects.first.id)).to be_falsey
      end

      it 'does not delete subject assicociated with set_member_subject' do
        subject.perform(subjects.last.id)
        expect(Subject.exists?(subjects.last.id)).to be_truthy
        expect(SetMemberSubject.exists?(subject_set_id: subject_set.id, subject_id: subjects.last.id)).to be_truthy
      end
    end
  end

  it 'should not call the orphan remover cleanup when disabled' do
    expect(Subjects::Remover).not_to receive(:new)
    expect(remover).not_to receive(:cleanup)
    subject.perform(subject_id)
  end
end
