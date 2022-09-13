module EventStreamSerializers
  class SubjectSerializer < ActiveModel::Serializer
    attributes :id, :locations, :metadata, :created_at, :updated_at
    type 'subjects'

    def locations
      object.ordered_locations.map do |loc|
        {
          loc.content_type => loc.url_for_format(:get)
        }
      end
    end
  end
end
