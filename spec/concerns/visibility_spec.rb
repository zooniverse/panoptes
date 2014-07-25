require 'spec_helper'

class VisibleClass < ActiveRecord::Base
  include Visibility
  attr_accessor :visibility, :id
  visibility_level :private, :role1, :role2
  
  def self.columns
    []
  end
  
  def initialize
    @visibility = 'public'
    @id = 1
    super
  end
end

RSpec.describe VisibleClass do
  let(:visible){ VisibleClass.new }
  it_behaves_like 'has visibility controls'
end
