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

  describe "#content" do
    it "should return organization content for the preferred language" do
      expect(serializer.content).to be_a( Hash )
      expect(serializer.content).to include(:title)
    end

    it "includes the defined content fields" do
      expect(serializer.content.keys).to contain_exactly(*Api::V1::OrganizationsController::CONTENT_PARAMS)
    end
  end

  describe "media links" do
    let(:links) { [:avatar, :background] }
    let(:serialized) { OrganizationSerializer.resource({}, Organization.where(id: organization.id), context) }

    it 'should include top level links for media' do
      expect(serialized[:links]).to include(*links.map{ |l| "projects.#{l}" })
    end

    it 'should include resource level links for media' do
      expect(serialized[:projects][0][:links]).to include(*links)
    end

    it 'should include hrefs for links' do
      serialized[:projects][0][:links].slice(*links).each do |_, linked|
        expect(linked).to include(:href)
      end
    end

    it 'should include the id for single links' do
      serialized[:projects][0][:links].slice(:avatar, :background).each do |_, linked|
        expect(linked).to include(:id)
      end
    end
  end
end
