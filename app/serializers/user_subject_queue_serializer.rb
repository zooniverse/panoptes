# This is also hacking around the lack of support for relations based
# on arrays of foreign keys. Hopefully it'll replaced with a normal
# restpack serializer when that's figured out. 

class UserSubjectQueueSerializer
  include RestPack::Serializer
  
  attributes :id, :links
  can_include :user, :workflow

  def self.key
    "subject_queues"
  end

  def links
    {subjects: @model.subject_ids,
     user: @model.user.id,
     workflow: @model.workflow.id}
  end

  def self.links
    links = super
    links["subject_queues.subjects"] = {
      href: "/subjects?subject_ids={subject_queues.subjects}",
      type: "subjects",
    }
    links
  end
end
