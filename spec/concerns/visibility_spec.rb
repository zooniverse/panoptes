require 'spec_helper'

class VisibleClass
  include Visibility

  attr_accessor :visibility, :id

  visibility_level :private, :role1, :role2

  def initialize
    @visibility = "public"
    @id = 1
  end
end

describe VisibleClass do
  let(:visible) { VisibleClass.new }

  it_behaves_like "has visibility controls"
end
