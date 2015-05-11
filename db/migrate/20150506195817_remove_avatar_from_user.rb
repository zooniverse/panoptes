class RemoveAvatarFromUser < ActiveRecord::Migration
  def change
    users_with_avatars = User.where("avatar IS NOT NULL")
    total = users_with_avatars.count
    users_with_avatars.find_each.with_index do |u,i|
      p "#{i+1} of #{total}"
      u.create_avatar(external_link: true,
                      content_type: "image/*",
                      src: u.avatar)
    end
    remove_column :users, :avatar, :text
  end
end
