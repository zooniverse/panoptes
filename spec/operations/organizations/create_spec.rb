require 'spec_helper'

describe Organizations::Create do
  let(:user){ create :user }
  let(:api_user){ ApiUser.new(user) }
  let(:params) do
    {
      display_name: "The Illuminati",
      description: "This organization is the most organized organization to ever organize",
      introduction: "org intro",
      announcement: "We dont exist",
      urls: [{label: "Blog", url: "http://blogo.com/example"}],
      primary_language: "zh-tw",
      categories: %w(stuff things moar)
    }
  end

  let(:operation) { described_class.with(api_user: api_user) }

  it 'creates an organization' do
    organization = operation.run!(**params)
    expect(organization).to be_persisted
  end

  it 'sets the urls, splitting out translatable content' do
    organization = operation.run!(**params)
    expect(organization.urls).to eq([{"label" => "0.label", "url" => "http://blogo.com/example"}])
    expect(organization.url_labels).to eq({"0.label" => "Blog"})
  end

  it 'sets the content attributes on its primary_content' do
    organization = operation.run!(**params)
    expect(organization.primary_content.introduction).to eq('org intro')
  end

  it 'sets the content attributes on itself' do
    organization = operation.run!(**params)
    expect(organization.introduction).to eq('org intro')
  end
end
