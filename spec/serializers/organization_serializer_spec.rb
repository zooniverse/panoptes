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
end
