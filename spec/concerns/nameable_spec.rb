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

describe NamedThing do
  let(:named) { n = NamedThing.create!(uniq_name: "test_name", name: "test_name"); n }
  let(:unnamed) { NamedThing.new }

  it_behaves_like "is uri nameable"
end
