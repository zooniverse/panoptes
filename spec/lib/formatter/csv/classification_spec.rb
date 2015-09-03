require 'spec_helper'

RSpec.describe Formatter::Csv::Classification do

  let(:project_headers) do
    %w( user_name user_ip workflow_id workflow_name workflow_version
        created_at gold_standard expert metadata annotations subject_data )
  end

  let(:subject) { build_stubbed(:subject) }

  let(:subject_data) do
    { "#{subject.id}" => subject.metadata.merge(retired: false) }
  end

  let(:subject_json_data) { subject_data.to_json }

  let(:ip_hash) do
    Digest::SHA1.hexdigest("#{classification.user_ip}#{expected_time}")
  end

  let(:formatted_data) do
    [ classification.user.login,
      ip_hash,
      classification.workflow_id,
      classification.workflow.display_name,
      classification.workflow_version,
      classification.created_at,
      classification.gold_standard,
      classification.expert_classifier,
      classification.metadata.to_json,
      classification.annotations.map {|ann| Formatter::Csv::AnnotationForCsv.new(classification, ann).to_h }.to_json,
      subject_json_data
    ]
  end

  let(:workflow) { build_stubbed(:workflow, build_contents: false) }
  let(:project) { build_stubbed(:project, workflows: [workflow]) }
  let(:classification) { build_stubbed(:classification, project: project, workflow: workflow, subject_ids: [subject.id]) }
  let(:formatter) { described_class.new(project) }

  describe "::project_headers?" do
    it 'should be have the expected headers' do
      expect(formatter.class.headers).to match_array(project_headers)
    end
  end

  describe "#to_array" do
    let!(:expected_time) { Time.now.to_i }

    before(:each) do
      allow(Subject).to receive(:where).with(id: classification.subject_ids).and_return([subject])
      allow(subject).to receive(:retired_for_workflow?).and_return(false)
      allow(workflow).to receive(:primary_content).and_return(build_stubbed(:workflow_content, workflow: workflow))
      allow(formatter).to receive(:salt).and_return(expected_time)
    end

    it 'return an array formatted classifcation data' do
      expect(formatter.to_array(classification)).to match_array(formatted_data)
    end

    context "when the subject has been retired for that workflow" do
      it 'return an array formatted classifcation data' do
        allow(subject).to receive(:retired_for_workflow?).with(classification.workflow).and_return(true)
        subject_data.deep_merge!("#{subject.id}" => { retired: true })
        expect(formatter.to_array(classification)).to match_array(formatted_data)
      end
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
        expect(user_id).to eq("not-logged-in-#{ip_hash}")
      end
    end
  end
end
