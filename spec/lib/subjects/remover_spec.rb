require 'spec_helper'

RSpec.describe Subjects::Remover do
  let(:workflow) { create(:workflow_with_subjects) }
  let(:user) { create(:user) }
  let(:subject_set) { create(:subject_set_with_subjects) }
  let(:subjects) { subject_set.subjects }
  let(:subject) { subjects.sample }
  let(:remover) { Subjects::Remover.new(subject.id) }

  describe "::remove" do

    it "should not remove a subject that has been classified" do
      create(:classification, subjects: [subject])
      expect { remover.cleanup }.to raise_error(Subjects::Remover::NonOrphan)
    end

    it "should not remove a subject that has been collected" do
      create(:collection, subjects: [subject])
      expect { remover.cleanup }.to raise_error(Subjects::Remover::NonOrphan)
    end

    it "should not remove a subject that has been in a talk discussion", :focus do
      pending "add the talk api client discussion check here"
    end

    it "should remove a subject that has not been used" do
      remover.cleanup
      expect { Subject.find(subject.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should remove the associated set_member_subjects" do
      sms_ids = subject.set_member_subjects.map(&:id)
      remover.cleanup
      expect { SetMemberSubject.find(sms_ids) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should remove the associated media resources" do
      locations = subjects.map { |s| create(:medium, linked: s) }
      media_ids = subject.reload.locations.map(&:id)
      remover.cleanup
      expect { Medium.find(media_ids) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
