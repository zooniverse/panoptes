require 'spec_helper'

class NamedThing < ActiveRecord::Base
  include Nameable
  self.table_name = "set_member_subjects"

  attr_accessor :uniq_name
  attr_accessible :uniq_name

  def model_uniq_name_attribute
    :uniq_name
  end
end

def create_named_thing
  name = "named_thing"
  NamedThing.create(uniq_name: name) do |named|
    named.owner_name = build(:owner_name, name: name, resource: named)
  end
end

RSpec.describe NamedThing do
  let(:named) { create_named_thing }
  let(:unnamed) { NamedThing.new }

  it_behaves_like "is owner nameable"
end
