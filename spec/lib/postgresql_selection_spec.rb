require 'spec_helper'

RSpec.describe PostgresqlSelection do
  let(:user) { create(:user) }
  let!(:sms) { create_list(:set_member_subject, 25, subject_set: workflow.subject_sets.first) }
  
  subject { PostgresqlSelection.new(workflow, user) }

  shared_examples "select for incomplete_project" do
    let(:args) { {} }
    
    context "when a user has only seen a few subjects" do
      let!(:uss) { create(:user_seen_subject, user: user, subject_ids: sms.sample(5).map(&:subject_id), workflow: workflow) }
      
      it 'should return an unseen subject' do
        expect(uss.subject_ids).to_not include(subject.select(**args.merge(limit: 1)).first)
      end

      it 'should no have duplicates' do
        result = subject.select(**args.merge(limit: 10))
        expect(result).to match_array(result.to_a.uniq)
      end

      it 'should always return the requested number of subjects' do
        20.times do |n|
          expect(subject.select(**args.merge(limit: n+1)).length).to eq(n+1)
        end
      end
    end

    context "when a user has seen most of the subjects" do
      let!(:uss) { create(:user_seen_subject, user: user, subject_ids: sms.sample(20).map(&:subject_id), workflow: workflow) }
      
      it 'should return as many subjects as possible' do
        15.times do |n|
          expect(subject.select(**args.merge(limit: n+5)).length).to eq(5)
        end
      end
    end
    
  end

  describe "#select" do
    context "grouped selection" do
      let(:workflow) { create(:workflow_with_subject_sets, grouped: true, prioritized: false, pairwise: false) }
      
      it_behaves_like "select for incomplete_project" do
        let(:args) { {subject_set_id: workflow.subject_sets.first.id} }
      end
    end

    describe "random selection" do
      let(:workflow) { create(:workflow_with_subject_sets, grouped: false, prioritized: false, pairwise: false) }

      it_behaves_like "select for incomplete_project"
    end
  end
end
