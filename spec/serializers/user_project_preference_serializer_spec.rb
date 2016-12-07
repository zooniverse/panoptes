require 'spec_helper'

describe UserProjectPreferenceSerializer do
  let(:user) { create(:user) }
  let!(:upps) do
    create_list(:user_project_preference, 2, user: user)
  end
  let(:project) { create(:project, display_name: "Aardvark Adventure") }
  let(:params) { { sort: "display_name" } }
  let(:serialized_page) do
    UserProjectPreferenceSerializer.page(
      params,
      UserProjectPreference.scope_for(:index, user),
      {}
    )
  end
  let(:result_ids) do
    serialized_page["project_preferences"].map{ |r| r[:id] }
  end

  describe "sorting" do
    before do
      create(:user_project_preference, user: user, project: project)
    end

    describe "updated_at field" do
      let(:params) { { sort: "updated_at" } }

      it "should respect the non-overriden sort order" do
        expected_ids = UserProjectPreference
          .where(user_id: user.id)
          .order(updated_at: :asc)
          .map{ |upp| upp.id.to_s }
        expect(result_ids).to eq(expected_ids)
      end
    end

    describe "project's display_name field" do
      let(:params) { { sort: "display_name" } }

      it "should respect the project's display_name sort order" do
        expected_ids = UserProjectPreference
          .where(user_id: user.id)
          .joins(:project)
          .order("projects.display_name")
          .map{ |upp| upp.id.to_s }
        expect(result_ids).to eq(expected_ids)
      end
    end

    describe "project's display_name and updated_at sorts" do
      let(:params) { { sort: "display_name,updated_at" } }

      it "should respect the both sort orders" do
        expected_ids = UserProjectPreference
          .where(user_id: user.id)
          .joins(:project)
          .order("projects.display_name")
          .order(updated_at: :asc)
          .map{ |upp| upp.id.to_s }
        expect(result_ids).to eq(expected_ids)
      end
    end
  end
end
