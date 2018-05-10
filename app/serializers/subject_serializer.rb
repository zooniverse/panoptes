class SubjectSerializer
  include Serialization::PanoptesRestpack
  include FilterHasMany

  attributes :id, :metadata, :locations, :zooniverse_id, :external_id,
    :created_at, :updated_at, :href

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
