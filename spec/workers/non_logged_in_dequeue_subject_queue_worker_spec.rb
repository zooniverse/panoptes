require "spec_helper"

RSpec.describe NonLoggedInDequeueSubjectQueueWorker do

  subject { described_class.new }

  it_behaves_like "a dequeue subject queue worker"
end
