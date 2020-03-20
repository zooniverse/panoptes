# frozen_string_literal: true

FactoryBot.define do
  factory :subject_group_member do
    subject { build(:subject) }
    subject_group { build(:subject_group) }
    sequence(:display_order) { |n| n }

    # after(:build) do |subject_group_member|
    #   unless subject_group_member.subject
    #     subject = build(:subject, project: subject_group_member.project)
    #     subject_group_member.subject = subject
    #   end
    # end
  end
end
