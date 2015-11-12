require 'spec_helper'

RSpec.describe UserProjectPreference, type: :model do
  let(:user_project) { build(:user_project_preference) }
  let(:factory) { :user_project_preference }

  it_behaves_like "has preferences scope"

  it 'should have a valid factory' do
    expect(user_project).to be_valid
  end

  it 'should require a project to be valid' do
    expect(build(:user_project_preference, project: nil)).to_not be_valid
  end

  it 'should require a user to be valid' do
    expect(build(:user_project_preference, user: nil)).to_not be_valid
  end

  describe "#summated_activity_count" do

    it "should summate correctly for activity_count only" do
      upp = build(:user_project_preference)
      expect(upp.summated_activity_count).to eq(upp.activity_count)
    end

    it "should summate correctly for legacy_count only" do
      upp = build(:legacy_user_project_preference)
      expected_count = upp.legacy_count.values.sum
      expect(upp.summated_activity_count).to eq(expected_count)
    end

    it "should summate correctly for busted legacy_count only" do
      upp = build(:busted_legacy_user_project_preference)
      expected_count = upp.send(:valid_legacy_count_values).sum
      expect(upp.summated_activity_count).to eq(expected_count)
    end

    context "when the count is a string" do
      let(:legacy_count) { '{"bars": 19, "candels": "10"}' }

      it "should summate correctly for legacy counts" do
        upp = build(:legacy_user_project_preference, legacy_count: legacy_count)
        expected_count = upp.legacy_count.values.map(&:to_i).sum
        expect(upp.summated_activity_count).to eq(expected_count)
      end
    end
  end

  describe "#destroy" do
    let(:pref) { create(:user_project_preference) }
    let(:project) { pref.project }

    it "should not cascade delete the relation", :aggregate_failures do
      expect(project).not_to be_nil
      pref.destroy
      expect(project.reload).not_to be_nil
    end
  end
end
