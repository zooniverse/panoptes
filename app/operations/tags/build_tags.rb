module Tags
  class BuildTags < Operation

    array :tag_array

    def execute
      tags = tag_array.try(:map) do |tag|
        name = tag.downcase
        Tag.where(name: name).first_or_create
      end
      tags
    end
  end
end
