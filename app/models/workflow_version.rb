class WorkflowVersion < ActiveRecord::Base
  belongs_to :workflow

  # These two aliases are used by Versioning because it doesn't support aliasing directly
  def major_version
    self.major_number
  end

  def major_version=(val)
    self.major_number = val
  end

  def minor_version
    self.minor_number
  end

  def minor_version=(val)
    self.minor_number = val
  end
end
