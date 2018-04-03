module ContentSerializer
  def content
    return @content if @content
    content = @model.primary_content.attributes.with_indifferent_access
    content.default = ""
    @content = content.slice(*fields)
  end
end
