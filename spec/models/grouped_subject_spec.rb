require 'spec_helper'

describe GroupedSubject, :type => :model do
  it "should have a valid factory" do
    expect(build(:grouped_subject)).to be_valid
  end

  it "must have a subject group" do
    expect(build(:grouped_subject, subject_group: nil)).to_not be_valid
  end

  it "must have a subject" do
    expect(build(:grouped_subject, subject: nil)).to_not be_valid
  end
end
