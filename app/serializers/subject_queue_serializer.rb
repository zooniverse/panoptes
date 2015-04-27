# This is also hacking around the lack of support for relations based
# on arrays of foreign keys. Hopefully it'll replaced with a normal
# restpack serializer when that's figured out. 

class SubjectQueueSerializer
  include RestPack::Serializer
  
  attributes :id
  can_include :user, :workflow, :subject_set

  def self.key
    "subject_queues"
  end

  def self.links
    links = super
    links["subject_queues.subjects"] = {
      href: "/subjects?sort=queue-{subject_queues.id}",
      type: "subjects",
    }
    links
  end
end
