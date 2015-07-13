class TagSerializer
  include RestPack::Serializer

  attributes :id, :href, :created_at, :updated_at, :popularity, :name

  def popularity
    @model.tagged_resources_count
  end
end
