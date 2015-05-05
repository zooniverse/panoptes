class Medium < ActiveRecord::Base
  belongs_to :linked, polymorphic: true

  before_save :create_path

  def create_path
    self.src = MediaStorage.stored_path(content_type, type, *path_opts)
  end

  def put_url
    MediaStorage.put_path(src, **attributes)
  end

  def get_url
    MediaStorage.get_path(src, **attributes)
  end
end
