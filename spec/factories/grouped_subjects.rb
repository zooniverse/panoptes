FactoryGirl.define do
  factory :grouped_subject do
    state { GroupedSubject.states.keys.sample }
    classification_count { 1 + rand(30) }
    subject_group
    subject
  end
end
