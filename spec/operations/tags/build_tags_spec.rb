require 'spec_helper'

describe Tags::BuildTags do

  let(:api_user) { ApiUser.new(build_stubbed(:user)) }
  let(:operation) { described_class.with(api_user: api_user) }
  let(:resource) { create(:project) }
  let!(:tag) { create(:tag, name: "waycool", resource: resource) }

  it "requires an array of tags" do
    expect{operation.run! tag_array: "uhoh" }.to raise_error(ActiveInteraction::InvalidInteractionError)
  end

  it "finds existing tags" do
    tags = ['waycool']
    expect{operation.run! tag_array: tags}.not_to change{Tag.count}
  end

  it "creates non-existant tags" do
    tags = ['new', 'tag']
    expect{operation.run! tag_array: tags}.to change{Tag.count}.by(2)
  end

  it "returns an array of Tag objects" do
    tags = ['new', 'tag']
    result = operation.run! tag_array: tags
    expect(result).to eq([Tag.find_by_name('new'), Tag.find_by_name('tag')])
  end
end
