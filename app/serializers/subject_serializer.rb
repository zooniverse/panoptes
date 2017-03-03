require 'panoptes/restpack_serializer'

class SubjectSerializer
  include Panoptes::RestpackSerializer
  include FilterHasMany

  attributes :id, :metadata, :locations, :zooniverse_id,
    :created_at, :updated_at, :href

  optional :retired, :already_seen, :finished_workflow, :favorite

  can_include :project, :collections, :subject_sets

  preload :locations, :project, :collections, :subject_sets

  def locations
    @model.ordered_locations.map do |loc|
      {
       loc.content_type => loc.url_for_format(@context[:url_format] || :get)
      }
    end
  end
end
