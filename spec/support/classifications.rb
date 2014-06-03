shared_examples "it has a classifications assocation" do

  context "when no classifications exist" do

    it "should return an empty array" do
      expect(relation_instance.classifications).to eq([])
    end
  end

  context "when classifications exist" do

    let(:classification) { build(:classification) }

    it "should return the linked classifications" do
      relation_instance.classifications << classification
      expect(relation_instance.classifications).to eq([classification])
    end
  end
end
