class Cassandra::Classification
  include Cequel::Record

  key :project_id, :int
  key :workflow_id, :int
  key :subject_id, :int
  key :workflow_version, :int
  key :user_ip, :inet
  key :user_id, :int
  key :classification_id, :int
  column :created_at, :timestamp
  column :updated_at, :timestamp
  column :user_group_id, :int
  column :completed, :boolean
  column :gold_standard, :boolean
  column :expert_classifier, :boolean
  column :metadata, :text
  column :annotations, :text

  after_create :save_subject

  def self.from_ar_model(classification)
    attrs = classification.attributes.dup
    attrs["classification_id"] = attrs.delete("id")
    attrs.delete("subject_ids").each do |subject_id|
      create!(attrs.merge(subject_id: subject_id))
    end
  end

  def workflow_version=(version)
    if version.is_a?(String)
      write_attribute(:workflow_version, version.split(".").first.to_i)
    else
      write_attribute(:workflow_version, version)
    end
  end

  def user_id=(uid)
    uid = uid ? uid : -1
    write_attribute(:user_id, uid)
  end

  def user_group_id=(ugid)
    ugid = ugid ? ugid : -1
    write_attribute(:user_id, ugid)
  end

  def annotations=(ann)
    write_attribute(:annotations, ann.to_json)
  end

  def metadata=(metadata)
    write_attribute(:metadata, metadata.to_json)
  end

  def save_subject
    Cassandra::Subject.create! project_id: project_id, workflow_id: workflow_id,
      subject_id: subject_id, workflow_version: workflow_version
  end
end
