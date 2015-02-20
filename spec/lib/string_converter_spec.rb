require 'spec_helper'

describe StringConverter do

  describe "::replace_spaces" do

    it "should return nil on invalid param" do
      expect(StringConverter.replace_spaces(nil)).to be_nil
    end

    context "with single spacing" do
      let(:string) { "New User" }

      it "should a return the correct result" do
        expect(StringConverter.replace_spaces(string)).to eq("New_User")
      end
    end

    context "with multiple spacing" do
      let(:string) { "New    User" }

      it "should a return the correct result" do
        expect(StringConverter.replace_spaces(string)).to eq("New_User")
      end
    end
  end
end
