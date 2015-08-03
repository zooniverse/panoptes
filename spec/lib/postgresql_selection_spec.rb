require 'spec_helper'

RSpec.describe PostgresqlSelection do

  shared_examples "select for incomplete_project" do
    let(:args) { {} }
    let(:unseen_count) do
      if ss_id = args[:subject_set_id]
        group_sms = SetMemberSubject.where(subject_set_id: ss_id)
        group_sms.count - group_sms.where(id: uss.subject_ids).count
      else
        SetMemberSubject.count - seen_count
      end
    end

    context "when a user has only seen a few subjects" do
      let(:seen_count) { 5 }
      let!(:uss) do
        subject_ids = sms.sample(seen_count).map(&:subject_id)
        create(:user_seen_subject, user: user, subject_ids: subject_ids, workflow: workflow)
      end

      it 'should return an unseen subject' do
        expect(uss.subject_ids).to_not include(subject.select(**args.merge(limit: 1)).first)
      end

      it 'should no have duplicates' do
        result = subject.select(**args.merge(limit: 10))
        expect(result).to match_array(result.to_a.uniq)
      end

      it 'should always return the requested number of subjects up to the unseen limit' do
        unseen_count.times do |n|
          expect(subject.select(**args.merge(limit: n+1)).length).to eq(n+1)
        end
      end
    end

    context "when a user has seen most of the subjects" do
      let(:seen_count) { 20 }
      let!(:uss) do
        subject_ids = sms.sample(seen_count).map(&:subject_id)
        create(:user_seen_subject, user: user, subject_ids: subject_ids, workflow: workflow)
      end

      it 'should return as many subjects as possible' do
        unseen_count.times do |n|
          results = subject.select(**args.merge(limit: n+unseen_count))
          expect(results.length).to eq(unseen_count)
        end
      end
    end
  end

  describe "#select" do
    let(:user) { create(:user) }
    let(:workflow) { Workflow.first }
    subject { PostgresqlSelection.new(workflow, user) }

    context "grouped selection" do

      before(:all) do
        created_workflow = create(:workflow_with_subject_sets, grouped: true)
        create_list(:set_member_subject, 25, subject_set: created_workflow.subject_sets.first)
      end
      after(:all) do
        [ Workflow, SetMemberSubject ].map { |klass| klass.destroy_all }
      end
      let(:sms) { SetMemberSubject.all }

      it_behaves_like "select for incomplete_project" do
        let(:args) { {subject_set_id: workflow.subject_sets.first.id} }
      end

      it 'should not select subjects not in the specified group' do
        create(:user_seen_subject,
               user: user,
               subject_ids: sms.sample(5).map(&:subject_id),
               workflow: workflow)
        set_id = workflow.subject_sets.first.id
        expect(SetMemberSubject.find(subject.select(subject_set_id: set_id))
                .map(&:subject_set_id)).to all( eq(set_id) )
      end
    end

    describe "random selection" do

      before(:all) do
        created_workflow = create(:workflow_with_subject_sets)
        create_list(:set_member_subject, 25, subject_set: created_workflow.subject_sets.first)
      end
      after(:all) do
        [ Workflow, SetMemberSubject ].map { |klass| klass.destroy_all }
      end
      let(:sms) { SetMemberSubject.all }

      it_behaves_like "select for incomplete_project"
    end

    describe "priority selection" do

      before(:all) do
        created_workflow = create(:workflow_with_subject_sets, prioritized: true)
        create_list(:set_member_subject, 25, :with_priorities, subject_set: created_workflow.subject_sets.first)
      end
      after(:all) do
        [ Workflow, SetMemberSubject ].map { |klass| klass.destroy_all }
      end
      let(:sms) { SetMemberSubject.all }

      it_behaves_like "select for incomplete_project"

      it 'should select subjects in desc order of the priority field' do
        desc_priority = sms.order(id: :desc).pluck(:id)
        result = subject.select(limit: desc_priority.size)
        desc_priority.each_with_index do |priority, index|
          expect(result[index]).to eq(priority)
        end
      end

      context "with an inverted sort order param" do

        it 'should select subjects in inverted order of the priority field' do
          asc_priority = sms.order(id: :asc).pluck(:id)
          result = subject.select(limit: asc_priority.size, order: :asc)
          asc_priority.each_with_index do |priority, index|
            expect(result[index]).to eq(priority)
          end
        end
      end
    end

    describe "priority and grouped selection" do
      before(:all) do
        created_workflow = create(:workflow_with_subject_sets, grouped: true, prioritized: true)
        subject_sets = created_workflow.subject_sets
        create_list(:set_member_subject, 13, :with_priorities, subject_set: subject_sets.first)
        create_list(:set_member_subject, 12, :with_priorities, subject_set: subject_sets.last)
      end
      after(:all) do
        [ Workflow, SetMemberSubject ].map { |klass| klass.destroy_all }
      end
      let(:subject_set_id) { SubjectSet.first.id }
      let(:sms) { SetMemberSubject.where(subject_set_id: subject_set_id) }

      it_behaves_like "select for incomplete_project"  do
        let(:args) { {subject_set_id: subject_set_id} }
      end

      it 'should only select subjects in the specified group' do
        desc_priority = sms.order(id: :desc).pluck(:id)
        result = subject.select(subject_set_id: subject_set_id)
        desc_priority.each_with_index do |priority, index|
          expect(result[index]).to eq(priority)
        end
      end

      context "with an inverted sort order param on the second set" do
        let(:subject_set_id) { SubjectSet.last.id }

        it 'should select subjects in inverted order of the priority field' do
          asc_priority = sms.order(id: :asc).pluck(:id)
          result = subject.select(subject_set_id: subject_set_id, order: :asc)
          asc_priority.each_with_index do |priority, index|
            expect(result[index]).to eq(priority)
          end
        end
      end
    end
  end
end
