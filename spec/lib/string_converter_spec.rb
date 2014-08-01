require 'spec_helper'

describe StringConverter do

  describe "::downcase_and_replace_spaces" do

    it "should return nil on invalid param" do
      expect(StringConverter.downcase_and_replace_spaces(nil)).to be_nil
    end

    context "with single spacing" do
      let(:string) { "New User" }

      it "should a return the correct result" do
        expect(StringConverter.downcase_and_replace_spaces(string)).to eq("new_user")
      end
    end

    context "with multiple spacing" do
      let(:string) { "New    User" }

      it "should a return the correct result" do
        expect(StringConverter.downcase_and_replace_spaces(string)).to eq("new____user")
      end
    end
  end
end
