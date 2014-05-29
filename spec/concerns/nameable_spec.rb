require 'spec_helper'

class NamedThing < ActiveRecord::Base
  include Nameable
  self.table_name = "set_member_subjects"
end

describe NamedThing do
  let(:named) { n = NamedThing.create!(name: "test_name"); n }
  let(:unnamed) { NamedThing.new }

  it_behaves_like "is uri nameable"
end
