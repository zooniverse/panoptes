class OrganizationSerializer
  include RestPack::Serializer

  attributes :id, :name, :display_name, :description, :introduction, :title, :href

 def title
   content[:title]
 end

 def description
   content[:description]
 end

 def introduction
   content[:introduction]
 end

 def content
   @content ||= _content
 end

 def fields
   %i(title description introduction)
 end

 def _content
   content = @model.content_for(@context[:languages])
   content = fields.map{ |k| Hash[k, content.send(k)] }.reduce(&:merge)
   content.default_proc = proc { |hash, key| "" }
   content
 end
end