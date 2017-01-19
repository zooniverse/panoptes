require 'spec_helper'

describe ClassificationSerializer do

  it "should preload the serialized associations" do
    create(:classification)
    expect_any_instance_of(Classification::ActiveRecord_Relation)
      .to receive(:preload)
      .with(:subjects)
      .and_call_original
    ClassificationSerializer.page({}, Classification.all, {})
  end

  describe "avoid heavy count queries on paging" do
    it "should manually deal with the paging information" do
      result = ClassificationSerializer.page({}, Classification.all, {})
      meta = result[:meta][:classifications]
      expect(meta[:count]).to eq(0)
      expect(meta[:page_count]).to eq(0)
      expect(meta[:previous_page]).to eq(0)
      expect(meta[:next_page]).to eq(2)
    end

    it "should handle the the previous page information" do
      result = ClassificationSerializer.page({page: 2}, Classification.all, {})
      meta = result[:meta][:classifications]
      expect(meta[:count]).to eq(0)
      expect(meta[:page_count]).to eq(0)
      expect(meta[:previous_page]).to eq(1)
      expect(meta[:next_page]).to eq(3)
    end
  end
end
