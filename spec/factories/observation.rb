# frozen_string_literal: true

FactoryBot.define do
  sequence :id_sequence, 1

  factory :observation, class: 'Inaturalist::Observation' do
    external_id { generate(:id_sequence) }
    metadata { { id: generate(:id_sequence) } }
    locations {
      [
        { 'image/jpeg' => 'https://static.inaturalist.org/photos/12345/large.JPG' },
        { 'image/jpeg' => 'https://static.inaturalist.org/photos/45678/large.JPG' }
      ]
    }
    initialize_with { new(**attributes) }
  end
end
