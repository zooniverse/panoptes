require 'spec_helper'

RSpec.describe Formatter::Csv::Classification do
  let(:project_headers) do
    %w( classification_id user_name user_id user_ip workflow_id workflow_name workflow_version
        created_at gold_standard expert metadata annotations subject_data )
  end
  let(:subject) { build_stubbed(:subject) }
  let(:subject_data) do
    { "#{subject.id}" => {retired: false}.merge(subject.metadata) }
  end
  let(:subject_json_data) { subject_data.to_json }
  let(:secure_user_ip) { SecureRandom.hex(10) }
  let(:cache) do
    double("Cache", subject: subject,
      retired?: false,
      workflow_at_version: workflow,
      workflow_content_at_version: double("WorkflowContent", strings: {}),
      secure_user_ip: secure_user_ip
    )
  end

  let(:formatted_data) do
    [ classification.id,
      classification.user.login,
      classification.user_id,
      secure_user_ip,
      classification.workflow_id,
      classification.workflow.display_name,
      classification.workflow_version,
      classification.created_at,
      classification.gold_standard,
      classification.expert_classifier,
      classification.metadata.to_json,
      classification.annotations.map {|ann| Formatter::Csv::AnnotationForCsv.new(classification, ann, cache).to_h }.to_json,
      subject_json_data
    ]
  end

  let(:workflow) { build_stubbed(:workflow, build_contents: false) }
  let(:project) { build_stubbed(:project, workflows: [workflow]) }
  let(:classification) { build_stubbed(:classification, project: project, workflow: workflow, subjects: [subject]) }
  let(:formatter) { described_class.new(project, cache) }

  describe "::project_headers?" do
    it 'should be have the expected headers' do
      expect(formatter.class.headers).to match_array(project_headers)
    end
  end

  describe "#to_array" do
    before(:each) do
      allow(Subject).to receive(:where).with(id: classification.subject_ids).and_return([subject])
      allow(workflow).to receive(:primary_content).and_return(build_stubbed(:workflow_content, workflow: workflow))
    end

    it 'return an array formatted classifcation data' do
      expect(formatter.to_array(classification)).to match_array(formatted_data)
    end

    context "when the subject has been retired for that workflow" do
      it 'return an array formatted classifcation data' do
        allow(cache).to receive(:retired?).with(subject.id, workflow.id).and_return(true)
        subject_data.deep_merge!("#{subject.id}" => { retired: true })
        expect(formatter.to_array(classification)).to match_array(formatted_data)
      end
    end

    context "when the classifier is logged out" do
      it 'should should return not logged in' do
        allow(classification).to receive(:user).and_return(nil)
        user_id = formatter.to_array(classification)[1]
        expect(user_id).to eq("not-logged-in-#{secure_user_ip}")
      end
    end
  end
end
