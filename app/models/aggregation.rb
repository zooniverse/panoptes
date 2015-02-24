class Aggregation < ActiveRecord::Base
  include RoleControl::ParentalControlled
  
  belongs_to :workflow
  belongs_to :subject
  
  can_through_parent :workflow, :update, :destroy, :update_links,
                     :destroy_links, :versions, :version

  validates_presence_of :workflow, :subject

  def self.scope_for(action, user, opts={})
    return super unless (action == :show || action == :index) && !user.is_admin?
    joins(:workflow).merge(Workflow.scope_for(:update, user, opts))
  end
end
