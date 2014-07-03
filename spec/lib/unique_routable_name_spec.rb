require 'spec_helper'

def check_uniqueness(name, resource_id=nil)
  UniqueRoutableName.unique?(name, resource_id)
end

describe UniqueRoutableName do

  describe '#unique?' do
    let(:unique_name) { 'punky_brewster' }

    it "should return false with an empty string" do
      expect(check_uniqueness("")).to be false
    end

    it "should return false with a nil string" do
      expect(check_uniqueness(nil)).to be false
    end

    context "when no users or user groups exist" do

      it "should be true for a unique name" do
        expect(check_uniqueness(unique_name)).to be true
      end
    end

    context "when a user exists" do
      let!(:user) { create(:user) }

      it "should be true for a unique name" do
        expect(check_uniqueness(unique_name)).to be true
      end

      it "should be false for a duplicate name" do
        expect(check_uniqueness(user.login)).to be false
      end

      it "should be false for a duplicate name with different case" do
        expect(check_uniqueness(user.login.upcase)).to be false
      end
    end

    context "when a user_group exists" do
      let!(:user_group) { create(:user_group) }

      it "should be true for a unique name" do
        expect(check_uniqueness(unique_name)).to be true
      end

      it "should be false for a duplicate name" do
        expect(check_uniqueness(user_group.display_name)).to be false
      end
    end

    context "when both a user and a user_group with different uniq names exist" do
      let!(:user) { create(:user) }
      let!(:user_group) { create(:user_group) }

      it "should be true for a unique name" do
        expect(check_uniqueness(unique_name)).to be true
      end

      it "should be false for the duplicate user name" do
        expect(check_uniqueness(user.login)).to be false
      end

      it "should be false for the duplicate group name" do
        expect(check_uniqueness(user_group.display_name)).to be false
      end
    end

    context "when a user and a user_group with the same uniq names exist" do
      let!(:setup_dups) do
          build(:user, login: unique_name).save(validate: false)
          create(:user_group, display_name: unique_name).save(validate: false)
      end

      it "should raise an error" do
        expect { check_uniqueness(unique_name) }.to raise_error(UniqueRoutableName::DuplicateRoutableNameError)
      end
    end
  end
end
