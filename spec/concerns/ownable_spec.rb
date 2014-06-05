require 'spec_helper'

class Owned < ActiveRecord::Base
  include Ownable
  self.table_name = "collections"
end

describe Owned, type: :model do
  let(:owned) do
    owned = Owned.new(name: "test")
    owned.owner = build(:user)
    owned
  end

  let(:not_owned) { Owned.new } 

  it_behaves_like "is ownable"
end
