class Classification < ActiveRecord::Base
  belongs_to :set_member_subject, counter_cache: true
  belongs_to :project, counter_cache: true
  belongs_to :user, counter_cache: true
  belongs_to :workflow, counter_cache: true
  belongs_to :user_group, counter_cache: true

  validates_presence_of :set_member_subject, :project, :workflow,
                        :annotations, :user_ip

  attr_accessible :project_id, :workflow_id, :set_member_subject_id,
                  :annotations, :user_id, :user_ip
end
