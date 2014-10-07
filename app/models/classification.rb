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

  validates :user, presence: true, if: :incomplete?

  attr_accessible :annotations, :completed, :user_ip
  
  can :show, :in_show_scope?
  can :update, :created_and_incomplete?
  can :destroy, :created_and_incomplete?

  def self.visible_to(actor, as_admin: false)
    ClassificationVisibilityQuery.new(actor, self).build(as_admin)
  end

  def self.can_create?(actor)
    true
  end

  def created_and_incomplete?(actor)
    creator?(actor) && incomplete?
  end

  def in_show_scope?(actor)
    self.class.visible_to(actor).exists?(self)
  end
  
  def creator?(actor)
    user == actor.user
  end

  def complete?
    completed
  end

  def incomplete?
    !completed
  end

  def anonymous?
    !user
  end
end
