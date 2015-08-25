class Cassandra::Subject
  include Cequel::Record

  key :project_id, :int
  key :workflow_id, :int
  key :workflow_version, :int
  key :subject_id, :int
end
