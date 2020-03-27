module Validators
  # Validator for Collection model
  # Validate that only one favorite collection is created per owner for each project
  class OneFavoritePerOwnerValidator < ActiveModel::Validator
    def validate(new_record)
      return unless new_record.owner

      records = new_record.owner.collections
      return unless records && new_record.favorite

      records.each do |record|
        new_record.errors[:favorite] = 'Only one favorite collection can be created per owner for each project' if record.favorite
      end
    end
  end
end
