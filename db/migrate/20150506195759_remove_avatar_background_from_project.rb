class RemoveAvatarBackgroundFromProject < ActiveRecord::Migration
  def change
    ps_with_avatar_or_background = Project.where.not(avatar: nil)
      .or(Project.where.not(background_image: nil))
    total = ps_with_avatar_or_background.count
    ps_with_avatar_or_background.find_each.with_index do |ps, i|
      p "#{i+1} of #{total}"
      if ps.avatar
        Medium.create!(external_link: true,
                       content_type: "image/*",
                       src: ps.avatar,
                       linked: ps,
                       type: "project_avatar")
      end

      if ps.background_image
        Medium.create!(external_link: true,
                       content_type: "image/*",
                       src: ps.background_iamge,
                       linked: ps,
                       type: "project_background")
      end
    end
    remove_column :projects, :avatar, :text
    remove_column :projects, :background_image, :text
  end
end
