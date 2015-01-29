class ClassificationSerializer
  include RestPack::Serializer
  attributes :id, :annotations, :created_at
  can_include :project, :user, :user_group

  def add_links(model, data)
    data = super(model, data)
    data[:links][:set_member_subjects] = model.set_member_subject_ids.map(&:to_s)
    data
  end

  def self.links
    links = super
    links["#{key}.set_member_subjects"] = {
      type: "set_member_subjects",
      href: "/set_member_subjects/{#{key}.set_member_subjects}"
    }
    links
  end
end
