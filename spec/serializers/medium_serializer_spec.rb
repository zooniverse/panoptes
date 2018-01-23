require 'spec_helper'

describe MediumSerializer do
  let(:result) do
    described_class.single({}, Medium.where(id: medium.id), {})
  end

  context "organization" do
    describe "attached_images" do
      let(:org) { create(:organization, build_media: true) }
      let(:medium) { org.attached_images.first }
      let(:medium_href) do
        "/organizations/#{org.id}/attached_images/#{medium.id}"
      end

      it "should return the attached image href", :focus do
        expect(result[:href]).to eq(medium_href)
      end
    end
  end

  context "field_guides" do
    describe "attached_images" do
      let(:field_guide) do
        create(:field_guide) do |fg|
          medium = create(:medium, type: "field_guide_attached_image", linked: fg)
          fg.attached_images << medium
        end
      end
      let(:medium) { field_guide.attached_images.first }
      let(:medium_href) do
        "/field_guides/#{field_guide.id}/attached_images/#{medium.id}"
      end

      it "should return the attached image href" do
        expect(result[:href]).to eq(medium_href)
      end
    end
  end
end
