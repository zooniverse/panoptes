require 'spec_helper'

RSpec.describe Medium, :type => :model do
  let(:medium) { build(:medium, src: nil) }

  it 'should not be private by default' do
    m = Medium.new
    expect(m.private).to be false
  end

  describe "#create_path" do
    it 'should create src path when saved' do
      medium.save!
      expect(medium.src).to be_a(String)
    end

    it 'should call MediaStorage with the content_type, type, and path_opts' do
      expect(MediaStorage).to receive(:stored_path)
        .with(medium.content_type, medium.type, *medium.path_opts)
      medium.create_path
    end
  end

  describe "#put_url" do
    it 'should call MediaStorage with the src and other attributes' do
      expect(MediaStorage).to receive(:put_path).with(medium.src, medium.attributes)
      medium.put_url
    end

    it 'should pass attributes as hash with indifferent access' do
      expect(MediaStorage).to receive(:put_path)
        .with(anything, be_a(HashWithIndifferentAccess))
      medium.put_url
    end
  end

  describe "#get_url" do
    it 'should call MediaStorage with the src and other attributes' do
      expect(MediaStorage).to receive(:get_path).with(medium.src, medium.attributes)
      medium.get_url
    end

    it 'should pass attributes as hash with indifferent access' do
      expect(MediaStorage).to receive(:get_path)
        .with(anything, be_a(HashWithIndifferentAccess))
      medium.get_url
    end
  end
end
