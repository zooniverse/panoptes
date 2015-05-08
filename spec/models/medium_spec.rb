require 'spec_helper'

RSpec.describe Medium, :type => :model do
  let(:medium) { build(:medium, src: nil) }

  it 'should not be private by default' do
    m = Medium.new
    expect(m.private).to be false
  end

  it 'should not be externally linked by default' do
    m = Medium.new
    expect(m.external_link).to be false
  end

  it 'should not be valid without a valid content_type' do
    m = build(:medium, content_type: "video/mp4")
    expect(m).to_not be_valid
  end

  it 'should be valid with a valid content_type' do
    m = build(:medium, content_type: "image/png")
    expect(m).to be_valid
  end

  context "when the src field is blank" do
    before(:each) do
      allow(MediaStorage).to receive(:stored_path).and_return(nil)
    end

    it 'should not be valid without a src' do
      expect(medium).to be_invalid
    end

    it 'should have a useful error message' do
      medium.valid?
      expect(medium.errors[:src]).to include("can't be blank")
    end
  end

  describe "#create_path" do
    context "when not externally linked" do

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

    context "when externally linked" do
      let(:medium) { create(:medium, external_link: true, src: nil) }
      it 'should not create a src path' do
        medium.save!
        expect(medium.src).to be_nil
      end
    end
  end

  describe "#put_url" do
    context "when not externally linked" do
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

    context "when externally linked" do
      let(:medium) { create(:medium, external_link: true) }
      it 'should return the src' do
        expect(medium.put_url).to eq(medium.src)
      end
    end
  end

  describe "#get_url" do
    context "when not externally linked" do
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

    context "when externally linked" do
      let(:medium) { create(:medium, external_link: true) }
      it 'should return the src' do
        expect(medium.get_url).to eq(medium.src)
      end
    end
  end
end
