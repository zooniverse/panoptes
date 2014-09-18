class Classification < ActiveRecord::Base
  extend ControlControl::Resource
  include RoleControl::Adminable

  belongs_to :set_member_subject, counter_cache: true
  belongs_to :project, counter_cache: true
  belongs_to :user, counter_cache: true
  belongs_to :workflow, counter_cache: true
  belongs_to :user_group, counter_cache: true

  validates_presence_of :set_member_subject, :project, :workflow,
    :annotations, :user_ip
  validates :completed, inclusion: { in: [ true, false ] }

  attr_accessible :annotations, :completed, :user_ip
  
  can :show, :in_show_scope?
  can :update, :created_and_incomplete?
  can :destroy, :created_and_incomplete?

  after_create :create_project_preference, :update_seen_subjects

  def self.visible_to(actor, as_admin: false)
    ClassificationVisibilityQuery.new(actor, self).build(as_admin)
  end

  def creator?(actor)
    user == actor.user
  end

  def incomplete?
    !completed
  end

  def in_show_scope?(actor)
    self.class.visible_to(actor).exists?(self)
  end

  def subject_id
    set_member_subject.subject_id
  end

  private

  def created_and_incomplete?(actor)
    creator?(actor) && incomplete?
  end
  
  def create_project_preference
    return unless !!user
    UserProjectPreference.where(user: user, project: project)
      .first_or_create do |up|
      up.email_communication = user.project_email_communication
      up.preferences = {}
    end
  end

  def update_seen_subjects
    return unless !!user
    UserSeenSubject.add_seen_subject_for_user(user: user,
                                              workflow: workflow,
                                              subject_id: subject_id)
  end
end
