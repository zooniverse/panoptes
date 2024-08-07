# frozen_string_literal: true

require 'spec_helper'

describe Inaturalist::SubjectImporter do
  let(:subject_set) { create(:subject_set) }
  let(:importer) { described_class.new(subject_set.project.owner.id, subject_set.id) }
  let(:locations) {
    [
      { 'image/jpeg' => 'https://static.inaturalist.org/photos/12345/large.JPG' },
      { 'image/jpeg' => 'https://static.inaturalist.org/photos/45678/large.JPG' }
    ]
  }

  describe '#to_subject' do
    let(:response) { JSON.parse(file_fixture('inat_observations.json').read) }
    let(:obs) { Inaturalist::Observation.new(response['results'][0]) }

    let(:new_subject) { importer.to_subject(obs) }

    it 'sets metadata correctly' do
      expect(new_subject.metadata).to eq(obs.metadata)
    end

    describe 'imported locations' do
      let(:imported_locations) { new_subject.locations }

      it 'sets external_link correctly' do
        expect(imported_locations.map(&:external_link)).to match_array([true, true])
      end

      it 'sets content_type correctly' do
        expect(imported_locations.map(&:content_type)).to match_array(['image/jpeg', 'image/jpeg'])
      end

      it 'sets src correctly' do
        expect(new_subject.locations.map { |l| { 'image/jpeg' => l.src } }).to eq(locations)
      end
    end

    context 'when there is an existing subject' do
      let!(:subject_actual) { create(:subject, subject_sets: [subject_set], external_id: obs.external_id) }

      it 'uses the existing resource' do
        expect(new_subject.id).to eq(subject_actual.id)
      end
    end
  end

  describe '#import_subjects' do
    let(:subjects_to_import) { build_list(:subject, 3, project: subject_set.project, uploader: subject_set.project.owner) }

    it 'imports an array of subjects' do
      expect { importer.import_subjects(subjects_to_import) }.to change(Subject, :count).by(3)
    end

    it 'includes the locations' do
      subjects_to_import.each do |s|
        Subject.location_attributes_from_params(locations).each { |locattrs| s.locations.build(locattrs) }
      end
      expect { importer.import_subjects(subjects_to_import) }.to change(Medium, :count).by(6)
    end
  end

  describe '#import_smses' do
    let(:subjects_to_import) { create_list(:subject, 3, project_id: subject_set.project.id) }
    let(:smses_to_import) do
      subjects_to_import.map { |s| build(:set_member_subject, subject_set: subject_set, subject: s, random: rand) }
    end

    it 'imports a list of SetMemberSubjects' do
      expect { importer.import_smses(smses_to_import) }.to change(SetMemberSubject, :count).by(3)
    end
  end

  describe '#build_smses' do
    let(:import_results_double) { instance_double('ActiveRecord::Import::Result', ids: [1, 2]) }
    let(:subject_one) { create(:subject) }

    it 'builds a list of unsaved SetMemberSubjects' do
      expect(importer.build_smses(import_results_double)).to match_array(
        [
          have_attributes(
            class: SetMemberSubject,
            subject_id: 1
          ),
          have_attributes(
            class: SetMemberSubject,
            subject_id: 2
          )
        ]
      )
    end

    context 'when there is an existing SMS' do
      let!(:sms_actual) { create(:set_member_subject, subject: subject_one, subject_set_id: subject_set.id) }
      let(:import_results_double) { instance_double('ActiveRecord::Import::Result', ids: [subject_one.id, 2]) }

      it 'uses the existing id' do
        expect(importer.build_smses(import_results_double)).to match_array(
          [
            have_attributes(
              class: SetMemberSubject,
              subject_id: subject_one.id,
              id: sms_actual.id
            ),
            have_attributes(
              class: SetMemberSubject,
              subject_id: 2
            )
          ]
        )
      end
    end
  end
end
