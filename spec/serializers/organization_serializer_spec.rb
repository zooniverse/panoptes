require 'spec_helper'

describe OrganizationSerializer do
  let(:organization) { create(:organization) }
  let(:context) { {languages: ['en'], fields: [:title]} }

  let(:serializer) do
    s = OrganizationSerializer.new
    s.instance_variable_set(:@model, organization)
    s.instance_variable_set(:@context, context)
    s
  end

  let(:organization_with_media) { create(:organization, build_media: true) }
  let(:links) { [:avatar, :background] }
  let(:serialized) { OrganizationSerializer.resource({include: 'avatar,background,owners'}, Organization.where(id: organization_with_media.id), context) }

  it_should_behave_like "a panoptes restpack serializer", "test_owner_include" do
    let(:resource) { organization }
    let(:includes) { %i(organization_roles projects pages) }
    let(:preloads) { OrganizationSerializer.preloads }
  end

  describe "includes avatar and background" do
    it "should include avatar" do
      expect(serialized[:linked][:avatars].map{ |r| r[:id] })
      .to include(organization_with_media.avatar.id.to_s)
    end

    it "should include background" do
      expect(serialized[:linked][:backgrounds].map{ |r| r[:id] })
      .to include(organization_with_media.background.id.to_s)
    end

    it "should include owners" do
      expect(serialized[:linked][:owners].map{ |r| r[:id] })
      .to include(organization_with_media.owner.id.to_s)
    end
  end

  describe "media links" do
    it "should include top level links for media" do
      expect(serialized[:links]).to include(*links.map{ |l| "organizations.#{l}" })
    end

    it "should include resource level links for media" do
      expect(serialized[:organizations][0][:links]).to include(*links)
    end

    it "should include hrefs for links" do
      serialized[:organizations][0][:links].slice(*links).each do |_, linked|
        expect(linked).to include(:href)
      end
    end

    it "should include the id for single links" do
      serialized[:organizations][0][:links].slice(:avatar, :background).each do |_, linked|
        expect(linked).to include(:id)
      end
    end
  end

  describe "#avatar_src" do
    let(:avatar) { double("avatar", external_link: external_url, src: src) }
    let(:src) { nil }
    let(:external_url) { nil }

    context "without external" do
      let(:src) { "http://subject1.zooniverse.org" }

      it "should return the src by default" do
        allow(organization).to receive(:avatar).and_return(avatar)
        expect(serializer.avatar_src).to eq(src)
      end
    end

    context "with an external url" do
      let(:external_url) { "http://test.example.com" }

      it "should return the external src if set" do
        allow(organization).to receive(:avatar).and_return(avatar)
        expect(serializer.avatar_src).to eq(external_url)
      end
    end
  end

  describe "#urls" do
    it "should return the translated version of the url labels" do
      urls = [{"label" => "Blog",
               "url" => "http://blog.example.com/"},
              {"label" => "Twitter",
               "url" => "http://twitter.com/example"}]
      expect(serializer.urls).to eq(urls)
    end
  end

  describe "#categories" do
    let(:result) do
      OrganizationSerializer.single(
        {},
        Organization.where(id: organization.id),
        {}
      )
    end
    it "should return the categories by default" do
      expect(result[:categories]).to match_array(organization.categories)
    end
  end
end
