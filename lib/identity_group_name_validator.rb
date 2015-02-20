class IdentityGroupNameValidator < ActiveModel::Validator
  def validate(user)
    if identity_group = user.try(:identity_membership).try(:user_group)
      unless identity_group.valid?
        user.errors[:"identity_group.display_name"].concat(identity_group.errors[:name])
      end
    else
      user.errors.add(:identity_group, "can't be blank")
    end
  end
end
