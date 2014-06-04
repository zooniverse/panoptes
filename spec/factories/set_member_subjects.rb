FactoryGirl.define do
  factory :set_member_subject do
    state { SetMemberSubject.states.keys.sample }
    subject_set
    subject
  end
end
