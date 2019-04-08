require 'spec_helper'

describe GoldStandardAnnotation, type: :model do
  let(:gsa) { build(:gold_standard_annotation) }

  it "should have a valid factory" do
    expect(gsa).to be_valid
  end

  it "must have a project" do
    gsa.project = nil
    expect(gsa).to_not be_valid
  end

  it "must have a subject" do
    gsa.subject = nil
    expect(gsa).to_not be_valid
  end

  it "must have a workflow" do
    gsa.workflow = nil
    expect(gsa).to_not be_valid
  end

  it "must have a user" do
    gsa.user = nil
    expect(gsa).to_not be_valid
  end

  it "must have a classification" do
    gsa.classification = nil
    expect(gsa).to_not be_valid
  end

  it "must have annotations" do
    gsa.annotations = nil
    expect(gsa).to_not be_valid
  end

  it "must have metadata" do
    gsa.metadata = nil
    expect(gsa).to_not be_valid
  end
end
