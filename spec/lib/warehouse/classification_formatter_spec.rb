require 'spec_helper'

RSpec.describe Warehouse::ClassificationFormatter do

  let(:project_headers) do
    %w( classification_id user_name user_id user_ip project_id workflow_id workflow_name workflow_version
        created_at updated_at completed gold_standard expert metadata annotations subject_data )
  end

  let(:subject) { build_stubbed(:subject) }

  let(:subject_data) do
    { "#{subject.id}" => {retired: false}.merge(subject.metadata) }
  end

  let(:subject_json_data) { subject_data.to_json }

  let(:ip_hash) do
    Digest::SHA1.hexdigest("#{classification.user_ip}#{expected_time}")
  end

  let(:cache) { double("Cache", subject: subject,
                                retired?: false,
                                workflow_at_version: workflow,
                                workflow_content_at_version: double("WorkflowContent", strings: {})) }

  let(:formatted_data) do
    base_data = {
      classification_id: classification.id,
      user_name: classification.user.login,
      user_id: classification.user_id,
      user_ip: ip_hash,
      project_id: classification.project_id,
      workflow_id: classification.workflow_id,
      workflow_name: classification.workflow.display_name,
      workflow_version: classification.workflow_version,
      created_at: classification.created_at,
      updated_at: classification.updated_at,
      completed: classification.completed,
      gold_standard: classification.gold_standard,
      expert: classification.expert_classifier,
      metadata: classification.metadata.to_json,
      subject_data: subject_json_data
    }

    [
      base_data.merge(Warehouse::AnnotationFormatter.format(classification.annotations[0], task_definition: {}, translations: {})),
      base_data.merge(Warehouse::AnnotationFormatter.format(classification.annotations[1], task_definition: {}, translations: {}))
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
    let!(:expected_time) { Time.now.to_i }

    before(:each) do
      allow(Subject).to receive(:where).with(id: classification.subject_ids).and_return([subject])
      allow(workflow).to receive(:primary_content).and_return(build_stubbed(:workflow_content, workflow: workflow))
      allow(formatter).to receive(:salt).and_return(expected_time)
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

    context "when the obfuscate_private_details flag is false" do
      it 'return the real classification ip in the array' do
        allow(formatter).to receive(:obfuscate).and_return(false)
        user_ip = formatter.to_array(classification)[0][:user_ip]
        expect(user_ip).to eq(classification.user_ip.to_s)
      end
    end

    context "when the classifier is logged out" do
      it 'should should return not logged in' do
        allow(classification).to receive(:user).and_return(nil)
        user_id = formatter.to_array(classification)[0][:user_name]
        expect(user_id).to eq("not-logged-in-#{ip_hash}")
      end
    end
  end
end
