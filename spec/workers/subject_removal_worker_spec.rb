require 'spec_helper'

RSpec.describe SubjectRemovalWorker do
  let(:subject_id) { 1 }
  let(:feature_name) { "remove_orphan_subjects" }
  let(:panoptes_client) { instance_double(Panoptes::Client) }
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
      stub_request(:get, "#{discussions_url}?focus_id=#{subject_id}&focus_type=Subject")
        .to_return(status: 200, body: '[]', headers: {})
    end

    before do
      Flipper.enable(feature_name)
    end

    context 'when running orphan remover cleanup function' do
      it 'should call the orphan remover cleanup when enabled' do
        expect(Subjects::Remover).to receive(:new).with(subject_id).and_return(remover)
        expect(remover).to receive(:cleanup)
        subject.perform(subject_id)
      end
    end

    context 'when deleting subjects' do
      it 'deletes subject not associated with set_member_subject' do
        stub_discussions_request(first_subject.id.to_i)
        subject.perform(first_subject.id, subject_set.id)
        expect(Subject.exists?(first_subject.id)).to be_falsey
      end

      it 'does not delete subject assicociated with another set_member_subject' do
        create(:set_member_subject, subject: second_subject, subject_set: subject_sets.first)
        create(:set_member_subject, subject: second_subject, subject_set: subject_sets.last)
        stub_discussions_request(second_subject.id.to_i)
        subject.perform(second_subject.id, subject_sets.first.id)
        Subject.where(id: second_subject.id).should exist
        SetMemberSubject.where(subject_set_id: subject_sets.first.id, subject_id: second_subject.id).should exist
      end
    end
  end

  it 'should not call the orphan remover cleanup when disabled' do
    expect(Subjects::Remover).not_to receive(:new)
    expect(remover).not_to receive(:cleanup)
    subject.perform(subject_id)
  end
end
