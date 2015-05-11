class RemoveAvatarBackgroundFromProject < ActiveRecord::Migration
  def change
    ps_with_avatar_or_background = Project.where("avatar IS NOT NULL OR background_image IS NOT NULL")
    total = ps_with_avatar_or_background.count
    ps_with_avatar_or_background.find_each.with_index do |ps, i|
      p "#{i+1} of #{total}"
      if ps.avatar
        ps.create_avatar(external_link: true,
                         content_type: "image/*",
                         src: ps.avatar)
      end

      if ps.background_image
        ps.create_background(external_link: true,
                             content_type: "image/*",
                             src: ps.background_image)
      end
    end
    remove_column :projects, :avatar, :text
    remove_column :projects, :background_image, :text
  end
end
