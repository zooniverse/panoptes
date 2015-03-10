require 'spec_helper'

class NonPaperTrailEnabled < ApplicationController; end

RSpec.describe ApplicationController, type: :controller do
  controller NonPaperTrailEnabled do
    def paper_trail_test
      render text: "testing paper trail before filters"
    end
  end

  describe "calling paper trail whodunnit before filter" do
    before(:each) do
      routes.draw { get "paper_trail_test" => "non_paper_trail_enabled#paper_trail_test" }
    end

    it "should not enable current user lookup" do
      expect(subject.send(:paper_trail_enabled_for_controller)).to be_falsey
    end

    it "should not call the current_user method" do
      expect(subject).not_to receive(:user_for_paper_trail)
      get :paper_trail_test
    end
  end
end
