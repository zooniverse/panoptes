# frozen_string_literal: true

FactoryBot.define do
  factory :subject_group do
    project { build(:project) }

    after(:build) do |subject_group|
      member = create(:subject_group_member, subject_group: subject_group)
      subject_group.members << member
    end
  end
end
