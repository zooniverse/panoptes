require 'spec_helper'

RSpec.describe ProjectPage, type: :model do
  it_behaves_like "is translatable" do
    let(:model) { create :project_page }
  end

  it_behaves_like "a versioned model"
end
