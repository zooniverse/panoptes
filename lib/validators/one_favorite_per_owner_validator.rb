module Validators
  # Validator for Collection model
  # Validate that only one favorite collection is created per owner for each project
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
