# frozen_string_literal: true

class SubjectSetCopier
  attr_reader :orig_subject_set, :new_project_id, :orig_set_member_subjects

  def initialize(orig_subject_set, new_project_id=nil)
    @orig_subject_set = orig_subject_set
    @new_project_id = new_project_id
  end

  def duplicate_subject_set_and_subjects
    orig_subject_set.dup.tap do |subject_set|
      @orig_set_member_subjects = orig_subject_set.set_member_subjects
      subject_set.project_id = new_project_id
      subject_set.set_member_subjects = copy_set_member_subjects
      subject_set.set_member_subjects_count = copy_set_member_subjects.size
    end
  end

  private

  def copy_set_member_subjects
    [].tap do |new_smss|
      orig_set_member_subjects.find_each do |sms|
        sms_attrs = { subject_id: sms.subject_id, priority: sms.priority }
        new_smss << SetMemberSubject.new(sms_attrs)
      end
    end
  end
end
