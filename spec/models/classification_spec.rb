require 'spec_helper'

describe Classification, :type => :model do
  it "should have a valid factory" do
    expect(build(:classification)).to be_valid
  end

  it "must have a project" do
    expect(build(:classification, project: nil)).to_not be_valid
  end

  it "must have an subjects" do
    expect(build(:classification, subject_ids: nil)).to_not be_valid
  end

  it "must have a workflow" do
    expect(build(:classification, workflow: nil)).to_not be_valid
  end

  it "must have a user_ip" do
    expect(build(:classification, user_ip: nil)).to_not be_valid
  end

  it "must have annotations" do
    expect(build(:classification, annotations: nil)).to_not be_valid
  end

  it "should be valid without a user" do
    expect(build(:classification, user: nil)).to be_valid
  end

  it 'should not be valid if incomplete with no user' do
    classification = build(:classification, user: nil, completed: false)
    expect(classification).to_not be_valid
  end

  it 'should have a reasonable message if it is incomplete with no user' do
    classification = build(:classification, user: nil, completed: false)
    classification.valid?
    expect(classification.errors[:user][0]).to match("Only logged in users can store incomplete classifications")
  end

  it 'should not be valid without workflow_version' do
    expect(build(:classification, workflow_version: nil)).to_not be_valid
  end

  describe "#metadata" do
    let(:metadata) { build(:classification).metadata }

    it 'must have started_at' do
      metadata.delete(:started_at)
      expect(build(:classification, metadata: metadata)).to_not be_valid
    end

    it 'must have finished_at' do
      metadata.delete(:finished_at)
      expect(build(:classification, metadata: metadata)).to_not be_valid
    end

    it 'must have user_language' do
      metadata.delete(:user_language)
      expect(build(:classification, metadata: metadata)).to_not be_valid
    end

    it 'must have user_agent' do
      metadata.delete(:user_agent)
      expect(build(:classification, metadata: metadata)).to_not be_valid
    end

    describe "seen_before attribute" do

      it 'should be valid when set to true' do
        expect(build(:already_seen_classification, metadata: metadata)).to be_valid
      end

      it 'should not be valid when set to nil' do
        expect(build(:already_seen_classification, metadata: metadata)).to be_valid
      end

      it 'should not be valid when set to false' do
        expect(build(:already_seen_classification, metadata: metadata)).to be_valid
      end
    end
  end

  describe "validate gold_standard" do
    let(:classification) { build(:classification, gold_standard: gold_standard) }

    context "when the gold standard value is set to false" do
      let(:gold_standard) { false }

      it "should not be valid" do
        expect(classification).to_not be_valid
      end

      it "should have the correct error message" do
        classification.valid?
        expect(classification.errors[:gold_standard])
          .to include('can not be set to false')
      end
    end

    context "when the gold standard value is set to true" do
      let(:gold_standard) { true }

      context "when the classification user is not authorised for expert mode" do

        it "should not be valid" do
          expect(classification).to_not be_valid
        end

        it "should have the correct error message" do
          classification.valid?
          expect(classification.errors[:gold_standard])
            .to include('classifier is not a project expert')
        end
      end

      context "when the classification user is authorised for expert mode" do

        it "should be valid" do
          classification.user = classification.project.owner
          expect(classification).to be_valid
        end
      end
    end
  end

  describe "::scope_for" do
    let(:user) { ApiUser.new(create(:user)) }
    let(:project) { create(:project, owner: user.owner) }
    let(:user_group) { create(:user_group) }
    let(:other_user_classification) { create(:classification) }
    let(:other_user) { ApiUser.new(other_user_classification.user) }
    let!(:membership) do
      create(:membership, roles: ['group_admin'], user: user.owner,
        user_group: user_group, state: :active)
    end

    describe "#show/index" do
      it 'should return an ActiveRecord::Relation' do
        expect(Classification.scope_for(:index, user)).to be_a(ActiveRecord::Relation)
      end

      it 'should return all classifications for an admin user' do
        classifications = [
          create(:classification, user: user.owner),
          other_user_classification
        ]
        user = ApiUser.new(create(:user, admin: true), admin: true)
        expect(Classification.scope_for(:show, user)).to match_array(classifications)
      end

      it 'should return all complete classifications the requesting user has made' do
        expected = other_user_classification
        expect(Classification.scope_for(:index, other_user)).to match_array(expected)
      end

      it 'should not return incomplete classifications for a project' do
        create(:classification, user: user.owner, completed: false)
        expect(Classification.scope_for(:show, user)).to be_empty
      end
    end

    describe "#project" do
      it 'should return all project classifications if the user can update it' do
        classifications = [
          create(:classification, project: project),
          create(:classification, project: project, completed: false)
        ]
        result = Classification.scope_for(:project, user)
        expect(result).to match_array(classifications)
      end

      it 'should not return any classifications if the user can not update it' do
        create(:classification, user: user.owner)
        result = Classification.scope_for(:project, other_user)
        expect(result).to be_empty
      end
    end

    describe "#incomplete" do
      it 'should return all incomplete a user has made' do
        expected = create(:classification, user: user.owner, completed: false)
        expect(Classification.scope_for(:incomplete, user)).to match_array(expected)
      end
    end

    describe "#gold_standard" do
      it 'should return all gold_standard project data' do
        gsc = create(:gold_standard_classification,
          project: project, user: project.owner
        )
        gsc.workflow.update_column(:public_gold_standard, true)
        expect(Classification.scope_for(:gold_standard, user)).to match_array(gsc)
      end
    end
  end

  describe "#creator?" do
    let(:user) { ApiUser.new(build(:user)) }

    it "should be truthy if a user is the classification's creator" do
      classification = build(:classification, user: user.owner)
      expect(classification.creator?(user)).to be_truthy
    end

    it "should be falsy if a user is not the classificaiton' creator" do
      classification = build(:classification)
      expect(classification.creator?(user)).to be_falsy
    end
  end

  describe "#incomplete?" do
    it "should be truthy if completed attribute is false" do
      expect(build(:classification, completed: false).incomplete?).to be_truthy
    end

    it "should be falsy if completed attribute is true" do
      expect(build(:classification, completed: true).incomplete?).to be_falsy
    end
  end

  describe "#user_groups" do
    let(:expected_user_group) { create(:user_group) }
    let(:classification_with_user_group) { create(:classifaction_with_user_group, user_group: expected_user_group) }

    it "should a single user_group" do
      expect(classification_with_user_group.user_group).to eq(expected_user_group)
    end
  end

  describe "#gold_standard?" do

    context "without it set" do

      it "should be falsey" do
        expect(build(:classification).gold_standard?).to be_falsey
      end
    end

    context "with it set" do

      it "should be truthy" do
        classification = build(:gold_standard_classification)
        expect(classification.gold_standard?).to be_truthy
      end
    end

    context "with an incorrect value for the gold standard key" do

      it "should be falsey" do
        classification = build(:fake_gold_standard_classification)
        expect(classification.gold_standard?).to be_falsey
      end
    end
  end

  describe "#seen_before?" do
    it "should be truthy if seen_before metadata attribute is true" do
      expect(build(:already_seen_classification).seen_before?).to be_truthy
    end

    it "should be falsey if missing the seen_before metadata attribute" do
      expect(build(:classification).seen_before?).to be_falsey
    end
  end
end
