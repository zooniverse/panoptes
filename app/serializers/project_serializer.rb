class ProjectSerializer
  include RestPack::Serializer
  attributes :id, :name, :display_name, :classifications_count,
    :subjects_count, :created_at, :updated_at, :available_languages,
    :content

  can_include :workflows, :subject_sets, :owner, :project_contents

  def content
    return unless @context[:languages]
    if content = @model.content_for(@context[:languages], @context[:fields])
      @context[:fields].map{ |k| Hash[k, content.send(k)] }.reduce(&:merge)
    else
      {}
    end
  end
end
