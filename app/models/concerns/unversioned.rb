# This module should not exist, but some models need to behave "like" a versioned resource,
# without having versioning added to them yet.
module Unversioned
  def latest_version_id
    0
  end

  def version_ids
    [latest_version_id]
  end
end
