require 'spec_helper'

def check_uniqueness(resource)
  UniqueRoutableName.new(resource).unique?
end

def set_resource_name(resource, name)
  attribute = resource.is_a?(User) ? :login : :display_name
  resource.send("#{attribute}=", name)
end

describe UniqueRoutableName do

  describe '#unique?' do
    let(:unique_name) { 'punky_brewster' }
    let(:resource) { [ User.new, UserGroup.new ].sample }

    it "should return false with an empty string" do
      set_resource_name(resource, "")
      expect(check_uniqueness(resource)).to be false
    end

    it "should return false with a nil string" do
      set_resource_name(resource, nil)
      expect(check_uniqueness(resource)).to be false
    end

    context "when no users or user groups exist" do

      it "should be true for a unique name" do
        set_resource_name(resource, unique_name)
        expect(check_uniqueness(resource)).to be true
      end
    end

    context "when a user exists" do
      let!(:user) { create(:user) }

      it "should be true for a unique name" do
        set_resource_name(user, unique_name)
        expect(check_uniqueness(user)).to be true
      end

      it "should be false for a duplicate name" do
        expect(check_uniqueness(user)).to be false
      end

      it "should be false for a duplicate name with different case" do
        set_resource_name(user, user.login.upcase)
        expect(check_uniqueness(user)).to be false
      end
    end

    context "when a user_group exists" do
      let!(:user_group) { create(:user_group) }

      it "should be true for a unique name" do
        set_resource_name(user_group, unique_name)
        expect(check_uniqueness(user_group)).to be true
      end

      it "should be false for a duplicate name" do
        expect(check_uniqueness(user_group)).to be false
      end
    end

    context "when both a user and a user_group with different uniq names exist" do
      let!(:user) { create(:user) }
      let!(:user_group) { create(:user_group) }

      it "should be true for a unique name" do
        set_resource_name(resource, unique_name)
        expect(check_uniqueness(resource)).to be true
      end

      it "should be false for the duplicate user name" do
        expect(check_uniqueness(user)).to be false
      end

      it "should be false for the duplicate group name" do
        expect(check_uniqueness(user_group)).to be false
      end
    end

    context "when a user and a user_group with the same uniq names exist" do
      let!(:setup_dups) do
          build(:user, login: unique_name).save(validate: false)
          create(:user_group, display_name: unique_name).save(validate: false)
      end

      it "should raise an error" do
        set_resource_name(resource, unique_name)
        expect { expect(check_uniqueness(resource)) }.to raise_error(UniqueRoutableName::DuplicateRoutableNameError)
      end
    end
  end
end
