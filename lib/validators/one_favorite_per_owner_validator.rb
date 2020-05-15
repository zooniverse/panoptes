module Validators
  # validator for Collection model
  # validate that only one favorite collection is created per owner for each project.
  # this validation technique may allow a duplicate favorite record be inserted into the database
  # due to the db the read isolation level of this transaction vs concurrent transactions
  # and the fact our validations exist in ruby land and not strictly enforced at the database layer
  # it's low probablity but worth noting here if folks wonder how it can happen
  class OneFavoritePerOwnerValidator < ActiveModel::Validator
    def validate(new_record)
      return unless new_record.owner && new_record.favorite

      owner_has_existing_favorite = new_record.owner.collections.where(favorite: true).exists?
      if owner_has_existing_favorite
        new_record.errors[:favorite] = 'Only one favorite collection can be created per owner for each project'
      end
    end
  end
end
