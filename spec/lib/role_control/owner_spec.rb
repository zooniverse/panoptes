require 'spec_helper'

class Owner < ActiveRecord::Base
  include ControlControl::Actor
  include RoleControl::Owner

  def self.table_name
    "collections"
  end
  
  def id
    1
  end
end

describe RoleControl::Owner, type: :model do
  let(:owner) { owner = Owner.new }
    
  let(:owned) { build(:project, owner: owner) }

  it_behaves_like "is an owner"
end
