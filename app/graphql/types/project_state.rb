module Types
  class ProjectState < BaseEnum
    value "DEVELOPMENT", "This project is still being built.", value: "development"
    value "LIVE", "This project is accepting classifications.", value: "live"
    value "PAUSED", "This project has completed the current dataset, but more data will be available soon.", value: "paused"
    value "FINISHED", "This project has completed the current dataset, and no data is expected to be added.", value: "finished"
  end
end
