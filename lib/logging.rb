module Logging
  def eventlog
    @eventlog ||= SemanticLogger[self.class]
  end
end
