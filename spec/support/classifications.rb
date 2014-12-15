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

shared_examples "it has a cached counter for classifications" do
  let(:classification_with_relation) do
    association_name = relation_instance.class.name.underscore.to_sym
    name = Classification.reflect_on_association(association_name).name
    create(:classification, name => relation_instance)
  end

  it "should cache the count of classficiatons" do
    expect(relation_instance.classifications_count).to eq(0)
  end

  context "when adding a classification" do

    let!(:add_classification) do
      classification_with_relation
      relation_instance.reload
    end

    it "should increment the count" do
      expect(relation_instance.classifications_count).to eq(1)
    end

    context "when deleting a classification" do

      it "should have a classification to destroy" do
        expect(relation_instance.classifications).to eq([classification_with_relation])
      end

      it "should decrement the count" do
        classification_with_relation.destroy
        relation_instance.reload
        expect(relation_instance.classifications_count).to eq(0)
      end
    end
  end
end
