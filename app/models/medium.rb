class Medium < ActiveRecord::Base
  include RoleControl::ParentalControlled

  belongs_to :linked, polymorphic: true

  before_save :create_path

  can_through_parent :linked, :update, :index, :show, :destroy, :update_links,
    :destroy_links, :translate, :versions, :version

  def self.inheritance_column
    nil
  end

  def indifferent_attributes
    attributes.dup.with_indifferent_access
  end

  def create_path
    self.src = MediaStorage.stored_path(content_type, type, *path_opts)
  end

  def put_url
    MediaStorage.put_path(src, indifferent_attributes)
  end

  def get_url
    MediaStorage.get_path(src, indifferent_attributes)
  end

  def put_file(file_path)
    MediaStorage.put_file(src, file_path, indifferent_attributes)
  end
end
