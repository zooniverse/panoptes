require 'spec_helper'
require 'formatter_csv_classification'

RSpec.describe Formatter::CSV::Classification do

  def project_headers
    %w( user_name user_ip workflow_id created_at
        gold_standard expert metadata annotations
        subject_data workflow_version)
  end

  def subject_data
    {
     "1" => { loudness: 11, brightness: -20, distance_from_earth: "42 light years" }
    }.to_json
  end

  def formatted_data
    [ classification.user.display_name,
      Digest::SHA1.hexdigest("#{classification.user_ip}#{expected_time}"),
      classification.workflow_id,
      classification.created_at,
      classification.gold_standard,
      classification.expert_classifier,
      classification.metadata.to_json,
      classification.annotations.to_json,
      subject_data,
      classification.workflow_version
    ]
  end

  let(:project) { build(:project) }
  let(:classification) { create(:classification, project: project) }
  let(:formatter) { Formatter::CSV::Classification.new(project) }

  describe "::project_headers?" do
    it 'should be have the expected headers' do
      expect(formatter.class.project_headers).to match_array(project_headers)
    end
  end

  describe "#to_array" do
    let!(:expected_time) { Time.now.to_i }

    before(:each) do
      allow(formatter).to receive(:subject_data).and_return(subject_data)
      allow(formatter).to receive(:salt).and_return(expected_time)
    end

    it 'return an array formatted classifcation data' do
      expect(formatter.to_array(classification)).to match_array(formatted_data)
    end

    context "when the obfuscate_private_details flag is false" do

      it 'return the real classification ip in the array' do
        allow(formatter).to receive(:obfuscate).and_return(false)
        user_ip = formatter.to_array(classification)[1]
        expect(user_ip).to eq(classification.user_ip.to_s)
      end
    end

    context "when the classifier is logged out" do
      it 'should should return not logged in' do
        allow(classification).to receive(:user).and_return(nil)
        user_id = formatter.to_array(classification)[0]
        expect(user_id).to eq("not logged in")
      end
    end
  end
end
