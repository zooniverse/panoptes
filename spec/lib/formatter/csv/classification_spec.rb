require 'spec_helper'

RSpec.describe Formatter::Csv::Classification do
  let(:project_headers) do
    %w( classification_id user_name user_id user_ip workflow_id workflow_name workflow_version
        created_at gold_standard expert metadata annotations subject_data subject_ids )
  end
  let(:subject) { build_stubbed(:subject) }
  let(:subject_data) do
    { "#{subject.id}" => {retired: false}.merge(subject.metadata) }
  end
  let(:subject_json_data) { subject_data.to_json }
  let(:subject_ids) { subject.id.to_s }
  let(:secure_user_ip) { SecureRandom.hex(10) }
  let(:cache) do
    instance_double("ClassificationDumpCache", subject: subject,
      retired?: false,
      workflow_at_version: workflow,
      secure_user_ip: secure_user_ip,
      subject_ids_from_classification: [subject.id]
    )
  end

  let(:formatted_data) do
    [
      [
        classification.id,
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
        subject_json_data,
        subject_ids
      ]
    ]
  end

  let(:workflow) { build_stubbed(:workflow) }
  let(:project) { build_stubbed(:project, workflows: [workflow]) }
  let(:classification) { build_stubbed(:classification, project: project, workflow: workflow, subjects: [subject]) }
  let(:formatter) { described_class.new(cache) }

  describe "#headers" do
    it 'should be have the expected headers' do
      expect(formatter.headers).to match_array(project_headers)
    end
  end

  describe "#to_rows" do
    before(:each) do
      allow(Subject).to receive(:where).with(id: classification.subject_ids).and_return([subject])
    end

    it 'uses the default annotation formatter' do
      allow(Formatter::Csv::AnnotationForCsv).to receive(:new).and_call_original
      formatter.to_rows(classification)
      expect(Formatter::Csv::AnnotationForCsv).to have_received(:new).twice
    end

    it 'return an array formatted classifcation data' do
      expect(formatter.to_rows(classification)).to match_array(formatted_data)
    end

    context "when the subject has been retired for that workflow" do
      it 'return an array formatted classifcation data' do
        allow(cache).to receive(:retired?).with(subject.id, workflow.id).and_return(true)
        subject_data.deep_merge!("#{subject.id}" => { retired: true })
        expect(formatter.to_rows(classification)).to match_array(formatted_data)
      end
    end

    context "when the classifier is logged out" do
      it 'should should return not logged in' do
        allow(classification).to receive(:user).and_return(nil)
        user_id = formatter.to_rows(classification)[0][1]
        expect(user_id).to eq("not-logged-in-#{secure_user_ip}")
      end
    end

    context 'when the classification.metadata classifier_version is >= 2.0' do
      before do
        updated_metadata = classification.metadata.merge('classifier_version' => '2.0')
        classification.metadata = updated_metadata
      end

      it 'uses the v2 annotation formatter' do
        allow(Formatter::Csv::V2::Annotation).to receive(:new).and_call_original
        formatter.to_rows(classification)
        expect(Formatter::Csv::V2::Annotation).to have_received(:new).twice
      end
    end
  end
end
