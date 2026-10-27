# frozen_string_literal: true

class UserAddedToCollectionMailer < ApplicationMailer
  layout false

  def added_to_collection(user, collection, roles)
    @user = user
    @collection = collection
    @roles = roles
    @email_to = user.email
    mail(to: @email_to, subject: "You've been added to a new Zooniverse collection")
  end
end
