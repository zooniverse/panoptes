# frozen_string_literal: true

FactoryBot.define do
  factory :cached_export do
    data { { 'project_id': 1, 'workflow_id': 3, 'user_id': 2, 'user_name': 'Dr Fox in Socks' } }
  end
end
