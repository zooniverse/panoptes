FactoryGirl.define do
  factory :set_member_subject do
    state { SetMemberSubject.states.keys.sample }
    classification_count { 1 + rand(30) }
    subject_set
    subject
  end
end
