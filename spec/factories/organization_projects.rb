# frozen_string_literal: true

FactoryBot.define do
  factory :organization_project do
    organization
    project
  end
end
