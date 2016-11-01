class OrganizationSerializer
  include RestPack::Serializer
  include ContentSerializer

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
end
