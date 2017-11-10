module Tags
  class BuildTags < Operation

    array :tag_array

    def execute
      tags = tag_array.try(:map) do |tag|
        name = tag.downcase
        Tag.find_or_initialize_by(name: name)
      end
      tags
    end
  end
end
