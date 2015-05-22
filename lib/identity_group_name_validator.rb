class IdentityGroupNameValidator < ActiveModel::Validator
  def validate(user)
    if identity_group = user.try(:identity_membership).try(:user_group)
      unless identity_group.valid?
        error_list = name_errors(identity_group)
        user.errors[:"identity_group.display_name"].concat(error_list)
      end
    else
      user.errors.add(:identity_group, "can't be blank")
    end
  end

  private

  def name_errors(identity_group)
    [].tap do |error_list|
      %i( display_name name ).each do |attr|
        attr_errors = identity_group.errors[attr]
        error_list.concat(attr_errors)
      end
    end.uniq
  end
end
