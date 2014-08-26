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

  attr_accessible :user_id, :project_id, :workflow_id, :user_group_id,
    :set_member_subject_id, :annotations, :user_ip
  
  can :show, :in_show_scope?
  can :update, :created_and_incomplete?
  can :destroy, :created_and_incomplete?

  def self.visible_to(actor, as_admin: false)
    return all if actor.is_admin? && as_admin
    where(where_user(actor)
          .or(where_project(actor))
          .or(where_group(actor)))
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

  private

  def self.where_user(actor)
    arel_table[:user_id].eq(actor.id)
  end

  def self.where_project(actor)
    projects = Project.scope_for(:update, actor).select(:id).to_sql
    arel_table[:project_id].in(Arel.sql(projects))
  end

  def self.where_group(actor)
    groups = actor.owner.user_groups.select(:id).to_sql
    arel_table[:user_group_id].in(Arel.sql(groups))
  end
  
  def created_and_incomplete?(actor)
    creator?(actor) && incomplete?
  end
end
