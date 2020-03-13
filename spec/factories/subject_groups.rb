FactoryBot.define do
  factory :subject_group do
    project
    subjects { [build(:subject)] }
  end
end
