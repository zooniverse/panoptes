require 'spec_helper'
require 'formatter_csv_classification'

RSpec.describe Formatter::CSV::Classification do

  def project_headers
    %w( user_id user_ip workflow_id created_at
        gold_standard expert metadata annotations
        subject_data workflow_version)
  end

  def subject_data
    {
     "1" => { loudness: 11, brightness: -20, distance_from_earth: "42 light years" }
    }.to_json
  end

  def formatted_data
    [ classification.user_id.hash,
     classification.user_ip.to_s,
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

    before(:each) do
      allow(formatter).to receive(:subject_data).and_return(subject_data)
    end

    it 'return an array formatted classifcation data' do
      expect(formatter.to_array(classification)).to match_array(formatted_data)
    end

    context "when the show user id flag is true" do

      it 'return the real user id in the array' do
        allow(formatter).to receive(:show_user_id).and_return(true)
        user_id = formatter.to_array(classification)[0]
        expect(user_id).to eq(classification.user_id)
      end
    end
  end
end
