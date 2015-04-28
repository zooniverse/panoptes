module BelongsToMany
  extend ActiveSupport::Concern

  class BelongsToManyBuilder < ActiveRecord::Associations::Builder::CollectionAssociation
    def macro; :belongs_to_many; end
  end

  module ClassMethods
    def belongs_to_many(name, scope=nil, opts={})
      reflection = BelongsToManyBuilder.build(self, name, scope, opts)
      ActiveRecord::Reflection.add_reflection(self, name, reflection)
    end
  end
end
