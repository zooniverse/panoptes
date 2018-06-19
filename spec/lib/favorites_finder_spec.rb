require 'spec_helper'

RSpec.describe FavoritesFinder do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:subjects) { create_list(:subject, 2) }
  let(:non_fav_subject) { subjects.first }
  let(:fav_subject) { subjects.last }
  let(:subject_ids) { subjects.map(&:id) }
  let(:collection) do
    create(:collection, owner: user, subjects: [fav_subject], favorite: true, projects: [project])
  end

  context "user has no favorites" do
    it "returns favorite as false" do
      expect(FavoritesFinder.find(user, project, subject_ids)).to eq([])
    end
  end

  context "user has favorites" do
    before { collection }
    it "favorite returns true for favorited subjects" do
      expect(FavoritesFinder.find(user, project, subject_ids)).to include(fav_subject.id)
    end

    it "favorite returns false for non-favorited subjects" do
      expect(FavoritesFinder.find(user, project, subject_ids)).to_not include(non_fav_subject.id)
    end
  end

  context "not logged in" do
    it "returns favorites as false" do
      expect(FavoritesFinder.find(nil, project, subject_ids)).to eq([])
    end
  end

  context "feature flag enabled" do
    it "returns an empty array" do
      collection
      Panoptes.flipper[:skip_favorites_finder].enable
      expect(FavoritesFinder.find(user, project, subject_ids)).to eq([])
    end
  end
end
