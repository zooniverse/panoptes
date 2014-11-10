require 'spec_helper'

describe Classification, :type => :model do
  it "should have a valid factory" do
    expect(build(:classification)).to be_valid
  end

  it "must have a project" do
    expect(build(:classification, project: nil)).to_not be_valid
  end

  it "must have a set_member_subject" do
    expect(build(:classification, set_member_subject: nil)).to_not be_valid
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

    it 'must have workflow_version' do
      metadata.delete(:workflow_version)
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

  describe "::visible_to" do
    let(:user) { ApiUser.new(create(:user)) }
    let(:project) { create(:project, owner: user.owner) }
    let(:user_group) { create(:user_group) }
    let!(:classifications) do
      create(:membership, roles: ['group_admin'], user: user.owner,
             user_group: user_group, state: :active)
      [create(:classification, user: user.owner),
       create(:classification, project: project),
       create(:classification, user_group: user_group),
       create(:classification)]
    end

    it 'should return an ActiveRecord::Relation' do
      expect(Classification.visible_to(user)).to be_a(ActiveRecord::Relation)
    end

    it 'should return all classifications for a project if the user can updateit' do
      expected = classifications[1]
      expect(Classification.visible_to(user)).to include(expected)
    end

    it 'should return all classifications for a user group if the user can update it' do
      expected = classifications[2]
      expect(Classification.visible_to(user)).to include(expected)
    end

    it 'should return all classifications a user has made' do
      expected = classifications[0]
      expect(Classification.visible_to(user)).to include(expected)
    end

    it 'should all classifications for an admin' do
      admin_double = double({ is_admin?: true })
      expect(Classification.visible_to(admin_double, as_admin: true))
        .to match_array(classifications)
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

  describe "#in_show_scope?" do
    let(:user) { ApiUser.new(create(:user)) }

    it "should be truthy if the classification is in the actor's visible_scope" do
      classification = create(:classification, user: user.owner)
      expect(classification.in_show_scope?(user)).to be_truthy

    end

    it "should be falsy if the classification is not in the actor's visible_scope" do
      classification = create(:classification)
      expect(classification.in_show_scope?(user)).to be_falsy
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
end
