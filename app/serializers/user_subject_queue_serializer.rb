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
    {set_member_subjects: @model.set_member_subject_ids,
     user: @model.user.id,
     workflow: @model.workflow.id}
  end

  def self.links
    links = super
    links["subject_queues.set_member_subjects"] = {
                                                   href: "/subjects?set_member_subject_ids={subject_queues.set_member_subjects}",
                                                   type: "set_member_subjects",
                                                  }
    links
  end
end
