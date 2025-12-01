# frozen_string_literal: true

FactoryBot.define do
  factory :subject_group do
    project { build(:project) }
    group_subject { build(:subject) }
    sequence(:key, &:to_s)
  end
end
