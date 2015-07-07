# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_seen_subject do
    transient do
      build_real_subjects true
    end
    user
    workflow
    subject_ids do
      if build_real_subjects
        #TODO: clean this up -> this cascading create_list always builds:
        # 7 Projects, 3 Workflows, 2 SubjectSets, 2 Subjects
        create_list(:set_member_subject, 2).map(&:subject).map(&:id)
      else
        (1..10).to_a.sample(2)
      end
    end
  end
end
