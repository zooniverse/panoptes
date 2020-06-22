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

      owner_favorite_collections = new_record.owner.collections.includes(:projects).where(favorite: true)
      owner_has_existing_fav_for_project = false

      owner_favorite_collections.each do |collection|
        if collection.project_ids.include?(new_record.project_ids.first)
          owner_has_existing_fav_for_project = true
        end
      end

      return unless owner_has_existing_fav_for_project

      new_record.errors[:favorite] = 'An owner can only have one favorite collection per project'
    end
  end
end
