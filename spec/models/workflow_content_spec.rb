require 'spec_helper'

RSpec.describe WorkflowContent, :type => :model do
  let(:content_factory) { :workflow_content }
  let(:parent_factory) { :workflow }

  it_behaves_like "is translated content"
end
