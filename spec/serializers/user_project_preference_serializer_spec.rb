require 'spec_helper'

describe UserProjectPreferenceSerializer do
  describe "activity_count" do
    let(:result) do
      described_class.single({}, UserProjectPreference.all, {})[:activity_count]
    end

    describe "activity count caching" do
      let!(:upp) { create(:user_project_preference) }

      it "should not use the result cache" do
        expect(Rails).not_to receive(:cache)
        result
      end

      it "should use the result cache if enabled" do
        Panoptes.flipper["upp_activity_count_cache"].enable
        expect_any_instance_of(ActiveSupport::Cache::NullStore)
          .to receive(:fetch)
          .with(
            "#{upp.class}/#{upp.id}/activity_count",
            {expires_in: UserProjectPreferenceSerializer::ACTIVITY_COUNT_CACHE_MINS.minutes}
          )
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
