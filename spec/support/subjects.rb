shared_examples "it has a subjects association" do
  context "when no subjects exist" do
    it "should return an empty array" do
      expect(relation_instance.subjects).to eq([])
    end
  end

  context "when linked subjects exist" do

    let(:subject) { build(:subject) }

    it "should return the linked subjects" do
      relation_instance.subjects << subject
      relation_instance.save!
      relation_instance.reload
      expect(relation_instance.subjects).to eq([subject])
    end
  end
end
