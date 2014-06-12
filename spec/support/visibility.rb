shared_examples "has visibility controls" do
  describe "::visibility_level" do
    it "should add a level to a the class's visibility levels" do
      described_class.visibility_level(:private, :role1, :role2)
      expect(described_class.visibility_levels).to include(:private)
      expect(described_class.visibility_levels[:private]).to include(:role1, :role2)
    end
  end

  describe "#current_visibility" do
    it "should return the visibility as a symbol" do
      expect(visible.current_visibility).to eq(visible.visibility.to_sym)
    end
  end

  describe "#is_public?" do
    it "should return true when the visibility is public" do 
      visible.visibility = "public"
      expect(visible.is_public?).to be_truthy
    end
  end

  describe "#roles_visible_to" do
    it "should return an array of arguments for Rolify#has_any_role" do
      expect(visible.roles_visible_to).to all( include(:name, :resource) )
    end
  end

  describe "#has_access?" do
    let(:actor) { create(:user) }
    it "should return true if it is public" do
      visible.visibility = "public"
      expect(visible.has_access?(actor)).to be_truthy
    end

    it "should return true if the actor has a required role" do
      level = visible.class.visibility_levels.keys.select{|k| k != :public}.sample
      role = visible.class.visibility_levels[level].sample
      actor.add_role(role, visible)
      visible.visibility = level.to_s
      expect(visible.has_access?(actor)).to be_truthy
    end

    it "should return false otherwise" do
      level = visible.class.visibility_levels.keys.select{|k| k != :public}.sample
      visible.visibility = level.to_s
      expect(visible.has_access?(actor)).to be_falsy
    end
  end
end
