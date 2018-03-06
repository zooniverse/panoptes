module ContentSerializer
  def content
    @content ||= _content
  end

  private

  def _content
    content = @model.primary_content.attributes.with_indifferent_access.dup
    content.default = ""
    content.slice(*fields)
  end
end
