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
end
