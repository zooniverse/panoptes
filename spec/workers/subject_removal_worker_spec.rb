require 'spec_helper'

RSpec.describe SubjectRemovalWorker do
  let(:subject_id) { 1 }
  let(:feature_name) { "remove_orphan_subjects" }
  let(:panoptes_client) { instance_double(Panoptes::Client) }
  let(:subject_remover) { described_class.new }
  let(:remover) { instance_double(Subjects::Remover, panoptes_client: panoptes_client) }

  describe 'flipper enabled' do
    let(:project) { create(:project) }
    let!(:subjects) { create_list(:subject, 2) }
    let!(:subject_sets) { create_list(:subject_set, 2, project: project) }
    let!(:subject_set) { create(:subject_set, project: project) }
    let(:discussions_url) { 'https://talk-staging.zooniverse.org/discussions' }
    let!(:first_subject) { subjects.first }
    let!(:second_subject) { subjects.second }

    def stub_discussions_request(subject_id)
      stub_request(:get, discussions_url)
        .with(query: { focus_id: subject_id, focus_type: 'Subject' })
        .to_return(status: 200, body: '{"discussions": []}', headers: {})
    end

    before do
      Flipper.enable(feature_name)
    end

    context 'when running orphan remover cleanup function' do
      it 'calls the orphan remover cleanup when enabled' do
        allow(Subjects::Remover).to receive(:new).with(subject_id, nil, nil).and_return(remover)
        allow(remover).to receive(:cleanup)
        subject_remover.perform(subject_id)
        expect(Subjects::Remover).to have_received(:new)
        expect(remover).to have_received(:cleanup)
      end
    end

    context 'when deleting subjects' do
      it 'deletes subject not associated with set_member_subject' do
        stub_discussions_request(first_subject.id)
        subject_remover.perform(first_subject.id, subject_set.id)
        expect(Subject.where(id: first_subject.id)).not_to exist
      end

      it 'does not delete subjects associated with another set_member_subject' do
        create(:set_member_subject, subject: second_subject, subject_set: subject_sets.first)
        create(:set_member_subject, subject: second_subject, subject_set: subject_sets.last)
        stub_discussions_request(second_subject.id)
        subject_remover.perform(second_subject.id, subject_sets.first.id)
        expect(Subject.where(id: second_subject.id)).to exist
        expect(SetMemberSubject.where(subject_set_id: subject_sets.first.id, subject_id: second_subject.id)).to exist
      end
    end
  end

  it 'should not call the orphan remover cleanup when disabled' do
    allow(Subjects::Remover).to receive(:new)
    subject_remover.perform(subject_id)
    expect(remover).not_to receive(:cleanup)
  end
end
