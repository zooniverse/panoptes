require 'spec_helper'

RSpec.describe Namer do
  describe "::set_name_fields" do
    context "no name field" do
      it 'should set name to the underscored, downcased, url escaped version of display_name' do
        hash = { display_name: "test   AGAIN!?" }
        Namer.set_name_fields(hash)
        expect(hash).to include(name: "test_again%21%3F")
      end
    end

    context "no display_name field" do
      it 'should set the display_name field equal to name field' do
        hash = { name: "test" }
        Namer.set_name_fields(hash)
        expect(hash).to include(display_name: "test")
      end
    end

    context "both display_name and name field" do
      it 'should do nothing' do
        hash = { name: "test", display_name: "tester asdf" }
        dupped_hash = hash.dup
        Namer.set_name_fields(dupped_hash)
        expect(dupped_hash).to eq(hash)
      end
    end
  end
end
