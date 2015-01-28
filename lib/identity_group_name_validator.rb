class IdentityGroupNameValidator < ActiveModel::Validator
  def validate(user)
    if user.identity_group
      unless user.identity_group.valid?
        user.errors[:"identity_group.name"].concat(user.identity_group.errors[:name])
      end
    else
      user.errors[:"identity_group"] = "must have identity_group"
    end
  end
end
