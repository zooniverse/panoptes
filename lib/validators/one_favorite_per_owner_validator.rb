module Validators
  # validator for Collection model
  # validate that only one favorite collection is created per owner for each project.
  # this validation technique may allow a duplicate favorite record be inserted into the database
  # due to the db the read isolation level of this transaction vs concurrent transactions
  # and the fact our validations exist in ruby land and not strictly enforced at the database layer
  # it's low probablity but worth noting here if folks wonder how it can happen
  class OneFavoritePerOwnerValidator < ActiveModel::Validator
    def validate(record)
      return unless record.owner && record.favorite

      owner_fav_collections = record.owner.collections.where(favorite: true)
      owner_fav_collections = owner_fav_collections.where.not(id: record.id) if record.persisted?
      owner_has_existing_fav_for_project = owner_fav_collections
        .joins(:projects)
        .where(projects: { id: record.project_ids })
        .exists?

      return unless owner_has_existing_fav_for_project

      record.errors[:favorite] = 'An owner can only have one favorite collection per project'
    end
  end
end
