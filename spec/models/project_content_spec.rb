require 'spec_helper'

RSpec.describe ProjectContent, :type => :model do
  let(:content_factory) { :project_content }

  it_behaves_like "is translated content"
end
