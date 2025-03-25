class AddSlugToProjectsCollectionsAndUsers < ActiveRecord::Migration
  def change
    %i(users projects collections user_groups).each do |table|
      add_column table, :slug, :string, default: "", index: true
    end

    project_count = Project.count
    Project.active.find_each.with_index do |project, i|
      p "#{i+1} of #{project_count}"
      project.slug = project.display_name.to_url
      project.save!
    end

    user_count = User.count
    User.active.find_each.with_index do |user, i|
      p "#{i+1} of #{user_count}"
      user.slug = user.display_name.to_url
      user.save!
    end

    collection_count = Collection.count
    Collection.active.find_each.with_index do |col, i|
      p "#{i+1} of #{collection_count}"
      col.slug = col.display_name.to_url
      col.save!
    end

    group_count = UserGroup.count
    UserGroup.active.find_each.with_index do |ug, i|
      p "#{i+1} of #{group_count}"
      ug.slug = ug.display_name.to_url
      ug.save!
    end
  end
end
