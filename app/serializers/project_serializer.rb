class ProjectSerializer
  include RestPack::Serializer
  attributes :id, :name, :display_name, :classifications_count, 
    :subjects_count, :created_at, :updated_at, :available_languages,
    :content

  can_include :workflows, :subject_sets, :owner, :project_contents

  def content
    if @context[:languages]
      content = @model.content_for(@content[:langauges], @context[:fields])
      @context[:fields].map{ |k| Hash.new(k, content.send(k)) }.reduce(&:merge)
    end
  end
end
