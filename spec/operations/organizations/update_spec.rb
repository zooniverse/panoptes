require 'spec_helper'

describe Organizations::Update do
  let(:user){ create :user }
  let(:api_user){ ApiUser.new(user) }
  let(:organization) { create :organization }

  let(:update_params) do
    {
      organization_params: {
        display_name: "The Illuminati",
        description: "This organization is the most organized organization to ever organize",
        introduction: "org intro",
        announcement: "We dont exist",
        urls: [{label: "Blog", url: "http://blogo.com/example"}],
        categories: %w(stuff things moar)
      }
    }
  end

  let(:operation) { described_class.with(api_user: api_user, id: organization.id.to_s) }

  it 'sets the untranslated attribute' do
    organization = operation.run!(update_params)
    organization.reload
    expect(organization.urls).to eq([{"label" => "0.label", "url" => "http://blogo.com/example"}])
    expect(organization.url_labels).to eq({"0.label" => "Blog"})
  end

  it 'sets the content attributes on itself' do
    organization = operation.run!(update_params)
    expect(organization.introduction).to eq('org intro')
  end
end
