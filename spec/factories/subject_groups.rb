# frozen_string_literal: true

FactoryBot.define do
  factory :subject_group do
    project { build(:project) }
    group_subject { build(:subject) }
    sequence(:key, &:to_s)

    after(:build) do |subject_group|
      member = build(:subject_group_member, subject_group: subject_group)
      subject_group.subject_group_members << member
    end
  end
end
