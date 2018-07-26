require 'spec_helper'

describe UserProjectPreferenceSerializer do
  describe "sorting" do
    let(:user) { create(:user) }
    let!(:upps) do
      create_list(:user_project_preference, 2, user: user)
    end
    let(:project) { create(:project, display_name: "Aardvark Adventure") }
    let(:params) { { sort: "display_name" } }
    let(:serialized_page) do
      UserProjectPreferenceSerializer.page(
        params,
        UserProjectPreference.all,
        {}
      )
    end
    let(:result_ids) do
      serialized_page["project_preferences"].map{ |r| r[:id] }
    end

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

  describe "activity_count" do
    let(:result) do
      described_class.single({}, UserProjectPreference.all, {})[:activity_count]
    end

    describe "count caching" do
      let!(:upp) { create(:user_project_preference) }
      let(:serializer_cache_key) do
        UserProjectPreferenceSerializer.serializer_cache_key(
          upp,
          Digest::MD5.hexdigest({}.to_json)
        )
      end

      before do
        allow_any_instance_of(ActiveSupport::Cache::NullStore)
          .to receive(:fetch)
          .with(serializer_cache_key)
          .and_call_original
      end

      it "should cache the results" do
        %w(count_activity count_activity_by_workflow).each do |method|
          expect_any_instance_of(ActiveSupport::Cache::NullStore)
            .to receive(:fetch)
            .with(
              "#{upp.class}/#{upp.id}/#{method}",
              {expires_in: UserProjectPreferenceSerializer::CACHE_MINS.minutes}
            )
        end
        result
      end
    end

    context "when the upp has an activity count" do
      let!(:upp) { create(:user_project_preference) }

      it "should return the upp activity_count" do
        expect(result).to eq(upp.activity_count)
      end
    end

    context "when the upp has legacy counts" do
      let!(:upp) { create(:legacy_user_project_preference) }

      it "should return the summated counts for each legacy workflow" do
        expect(result).to eq(upp.legacy_count.values.sum)
      end
    end

    context "when the user has busted legacy counts" do
      let!(:upp) { create(:busted_legacy_user_project_preference) }

      it "should return the summated counts for each valid legacy workflow" do
        expect(result).to eq(upp.send(:valid_legacy_count_values).sum)
      end
    end

    context "when the upp has no activity count" do
      let(:project) { create(:project_with_workflow) }
      let(:upp) { create(:user_project_preference, project: project, activity_count: nil) }
      let(:user) { upp.user }
      let(:workflow) { project.workflows.first }
      let!(:user_seens) do
        create(:user_seen_subject, user: user, workflow: workflow).tap do |uss|
          create(:classification, user: user, workflow: workflow, subject_ids: uss.subject_ids)
        end
      end
      let(:result) do
        described_class.single({}, UserProjectPreference.all, {})
      end

      it "should return the correct count from user seen subjects" do
        expect(result[:activity_count]).to eq(user_seens.subject_ids.size)
      end

      it "returns the workflow's seen subject count" do
        workflow_count = result[:activity_count_by_workflow][:"#{workflow.id}"]
        expect(workflow_count).to eq(user_seens.subject_ids.size)
      end

      context "when the user has classified on more than 1 project" do

        it "should return the specific project activity count from user seen subjects" do
          create(:user_seen_subject, user: user, build_real_subjects: false)
          expect(result[:activity_count]).to eq(user_seens.subject_ids.size)
        end
      end
    end
  end
end
