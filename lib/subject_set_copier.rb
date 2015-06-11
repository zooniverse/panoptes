class SubjectSetCopier

  attr_reader :orig_subject_set, :new_project_id, :orig_set_member_subjects,
   :copied_subject_set

  def initialize(orig_subject_set, new_project_id=nil)
    @orig_subject_set = orig_subject_set
    @new_project_id = new_project_id
  end

  def duplicate_subject_set_and_subjects
    orig_subject_set.dup.tap do |subject_set|
      @copied_subject_set = copied_subject_set
      @orig_set_member_subjects = orig_subject_set.set_member_subjects
      subject_set.project_id = new_project_id
      subject_set.set_member_subjects_count = 0
      subject_set.set_member_subjects = copy_set_member_subjects
    end
  end

  private

  def copy_set_member_subjects
    [].tap do |new_smss|
      orig_set_member_subjects.find_each do |sms|
        sms_attrs = { subject_set: copied_subject_set, subject_id: sms.subject_id }
        new_smss << SetMemberSubject.new(sms_attrs)
      end
    end
  end
end
