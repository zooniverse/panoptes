# frozen_string_literal: true

FactoryBot.define do
  factory :subject_group_member do
    subject { create(:subject, :with_mediums, num_media: 1) } # rubocop:disable RSpec/EmptyLineAfterSubject
    subject_group { build(:subject_group) }
    sequence(:display_order) { |n| n }
  end
end
