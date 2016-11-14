module ContentSerializer
  extend ActiveSupport::Concern

  def _content
    content = @model.content_for(@context[:languages])
    content = fields.map{ |k| Hash[k, content.send(k)] }.reduce(&:merge)
    content.default_proc = proc { |hash, key| "" }
    content
  end

  def content
    @content ||= _content
  end
end
